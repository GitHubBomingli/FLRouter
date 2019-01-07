//
//  FLRouter.h
//  IShangBan
//
//  Created by 伯明利 on 2018/11/29.
//  Copyright © 2018 ishangban. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class FLRouter, FLRouterOption;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, FLRouterTransformStyle) {
    FLRouterTransformStylePush,
    FLRouterTransformStylePresent,
    FLRouterTransformStyleOther
}; // 转场动画

typedef void(^FLCompletionHandler)(id _Nullable result, NSError  * _Nullable error);

@protocol FLRouterDelegate <NSObject>

/**
 返回请求路径（不能包含字符“/”）
 */
+ (NSString *)routerPath;

/**
 实现页面跳转并返回结果
 */
+ (void)handleRequestWithTarget:(nonnull UIViewController *)target parameters:(nullable NSDictionary *)parameters option:(FLRouterOption *)option completionHandler:(nullable FLCompletionHandler)completionHanlder;

@end

@interface FLRouterOption : NSObject

/**
 通过设置shareOption的属性对全局进行设置
 */
+ (instancetype)shareOption;

/**
 转场动画，默认FLRouterTransformStylePush
 */
@property (nonatomic, assign) FLRouterTransformStyle transformStyle;

/**
 是否有动画，默认YES
 */
@property (nonatomic, assign) BOOL animated;

@end

@interface FLRouterRequest : NSObject

/**
 路径：支持连续的路径，用字符“/”分割（push）。定义方式请参考FLRouterKeyPaths.plist文件，也可通过接口获取配置表后修改路径
 */
@property (nonatomic, copy) NSString *routerPath;

/**
 参数
 */
@property (nonatomic, strong) NSDictionary *parameters;

/**
 跟进路径和参数构造方法

 @param routerPath 路径
 @param parameters 参数
 @return 请求实例
 */
- (instancetype)initWithRouterPath:(nonnull NSString *)routerPath parameters:(nullable NSDictionary *)parameters;

/**
 跟进URL对象构造方法

 @param URL URL对象包含路径和参数
 @return 请求实例
 */
- (instancetype)initWithURL:(nonnull NSURL *)URL;

/**
 配置选项
 */
@property (nonatomic, strong, readonly) FLRouterOption *option;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@end

@interface FLRouter : NSObject

/**
 获取默认的路由
 */
+ (instancetype)defaultRouter;

/**
 执行对应的请求，并返回执行结果

 @param request 请求
 @param topViewController 当前controller，为空时默认取最上面的一个
 @param completionHanlder 执行结果回调
 */
- (void)handleRequest:(nonnull FLRouterRequest *)request topViewController:(nullable UIViewController *)topViewController completionHandler:(nullable FLCompletionHandler)completionHanlder;

@end

NS_ASSUME_NONNULL_END
