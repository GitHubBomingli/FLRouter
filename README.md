# FLRouter(路由)
## 简介
页面跳转
## 使用规则：
1、在**FLRouterKeyPaths.plist**文件中定义相应的路径；  
2、在跳转目标类中遵守并实现协议`<FLRouterDelegate>`;  
3、在要实行跳转的地方根据路径对应的**key**实例化**Request**，并根据具体需要设置参数等；  
4、使用`FLRouter.defaultRouter`执行请求。  
  
***备注：如果需要的话，路径也可以通过接口获取。***
