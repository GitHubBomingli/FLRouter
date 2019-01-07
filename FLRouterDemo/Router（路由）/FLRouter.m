//
//  FLRouter.m
//  IShangBan
//
//  Created by 伯明利 on 2018/11/29.
//  Copyright © 2018 ishangban. All rights reserved.
//

#import "FLRouter.h"
#import <objc/runtime.h>

#ifdef DEBUG
#define FLRouterLog(format, ...) NSLog((@"*** FLRouter *** \n%s [Line %d] " format), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define FLRouterLog(...)
#endif

@implementation FLRouterOption

+ (instancetype)shareOption {
    static FLRouterOption *option = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        option = [[FLRouterOption alloc] init];
    });
    return option;
}

- (instancetype)init {
    if (self = [super init]) {
        self.transformStyle = FLRouterTransformStylePush;
        self.animated = YES;
    }
    return self;
}

@end

@implementation FLRouterRequest {
    FLRouterOption *_option;
}

- (instancetype)initWithRouterPath:(NSString *)routerPath parameters:(NSDictionary *)parameters {
    self.routerPath = routerPath;
    self.parameters = parameters;
    return self;
}

- (instancetype)initWithURL:(NSURL *)URL {
    NSString *path = [URL path];
    path = [path stringByReplacingOccurrencesOfString:@".com" withString:@""];
    path = [path stringByReplacingOccurrencesOfString:@".cn" withString:@""];
    self.routerPath = path;
    
    NSString *parameterStr = [[URL query] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    NSArray *parameterArr = [parameterStr componentsSeparatedByString:@"&"];
    for (NSString *parameter in parameterArr) {
        NSArray *parameterBoby = [parameter componentsSeparatedByString:@"="];
        if (parameterBoby.count == 2) {
            [dic setObject:parameterBoby[1] forKey:parameterBoby[0]];
        } else {
            FLRouterLog(@"URL%@参数有误", URL);
        }
    }
    self.parameters = dic;
    return self;
}

- (FLRouterOption *)option {
    if (!_option) {
        _option = [[FLRouterOption alloc] init];
        // 跟进shareOption的属性列表赋值
        u_int count = 0;
        objc_property_t *properties = class_copyPropertyList([FLRouterOption class], &count);
        for (int i = 0; i < count; i++) {
            const char *propertyName = property_getName(properties[i]);
            NSString *key = [NSString stringWithCString:propertyName encoding:NSUTF8StringEncoding];
            id value = [[FLRouterOption shareOption] valueForKey:key];
            [_option setValue:value forKey:key];
        }
    }
    return _option;
}

@end

@interface FLRouter ()

@property (nonatomic, strong) NSMutableDictionary *classes;

@property (nonatomic, strong) NSMutableDictionary *keyPaths;

@end

@implementation FLRouter

+ (instancetype)defaultRouter {
    static FLRouter *router = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        router = [[FLRouter alloc] init];
    });
    return router;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 获取全部class
        int count = objc_getClassList(NULL, 0);
        Class *classes = (Class *)malloc(sizeof(Class) * count);
        objc_getClassList(classes, count);
        // 协议
        Protocol *delegate = @protocol(FLRouterDelegate);
        // 遍历class
        for ( int i = 0; i < count; i ++) {
            Class cls = classes[i];
            // 遍历class及其父类，获取遵守协议的class
            for (Class thisCls = cls ; nil != thisCls ; thisCls = class_getSuperclass(thisCls)) {
                // 是否遵守协议
                if (!class_conformsToProtocol(thisCls, delegate)) continue;
                // 是否实现协议方法
                if (![(id)thisCls respondsToSelector:@selector(routerPath)] || ![(id)thisCls respondsToSelector:@selector(handleRequestWithTarget:parameters:option:completionHandler:)]) continue;
                // 保存遵守协议的class
                self.classes[[(id)thisCls routerPath]] = thisCls;
                break;
            }
        }
        if (classes) free(classes);
    }
    return self;
}

- (void)handleRequest:(FLRouterRequest *)request topViewController:(UIViewController *)topViewController completionHandler:(FLCompletionHandler)completionHanlder {
    topViewController = topViewController ?: [FLRouter currentViewController];
    NSError *error = nil;
    
    // paths的元素可能是路径或路径对应的key
    // 获取路径集合，并去除无效的路径
    NSString *path = request.routerPath;
    path = [path stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
    NSMutableArray <NSString *>*paths = [NSMutableArray arrayWithArray:[path componentsSeparatedByString:@"/"]];
    [paths removeObject:@""];
    
    // 如果包含多个路径，则使用Push的方式，且只有最后一个页面才会有动画
    BOOL animated = request.option.animated;
    if (paths.count > 1) {
        request.option.transformStyle = FLRouterTransformStylePush;
        request.option.animated = NO;
    }
    
    // 遍历路径，依次推出对应的页面
    for (NSInteger index = 0; index < paths.count; index ++) {
        // 只有最后一个推出的页面才会有动画
        FLRouterOption *option = request.option;
        if (index == paths.count - 1) {
            option.animated = animated;
        }
        
        // 获取具体的路径
        NSString *routerPath = self.keyPaths[paths[index]] ?: paths[index];
        // 获取路径对应的class
        Class <FLRouterDelegate>class = self.classes[routerPath];
        if (class) {
            // class执行request请求
            [class handleRequestWithTarget:topViewController parameters:request.parameters option:request.option completionHandler:^(id  _Nullable result, NSError * _Nullable error) {
                if (error) FLRouterLog(@"%@", error);
                if (completionHanlder) completionHanlder(result, error);
            }];
        } else {
            error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:NSURLErrorUnsupportedURL userInfo:@{NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"未找到routerPath：%@ 对应的资源", request.routerPath]}];
            break;
        }
    }
    if (error) {
        FLRouterLog(@"%@", error.localizedFailureReason);
        if (completionHanlder) completionHanlder(nil, error);
    }
}

- (NSMutableDictionary *)classes {
    if (!_classes) {
        _classes = [NSMutableDictionary dictionary];
    }
    return _classes;
}

- (NSMutableDictionary *)keyPaths {
    if (!_keyPaths) {
        // 获取本地默认的路径，也可以通过接口获取
        NSString *path = [[NSBundle mainBundle] pathForResource:@"FLRouterKeyPaths" ofType:@"plist"];
        _keyPaths = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    }
    return _keyPaths;
}

+ (UIViewController*)currentViewController {
    UIViewController* vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (1) {
        if ([vc isKindOfClass:[UITabBarController class]]) {
            vc = ((UITabBarController*)vc).selectedViewController;
        }
        if ([vc isKindOfClass:[UINavigationController class]]) {
            vc = ((UINavigationController*)vc).visibleViewController;
        }
        if (vc.presentedViewController) {
            vc = vc.presentedViewController;
        } else {
            break;
        }
    }
    return vc;
}

@end
