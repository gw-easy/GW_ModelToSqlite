//
//  NSObject+GW_Model.h
//  gw_test
//
//  Created by gw on 2018/3/29.
//  Copyright © 2018年 gw. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - 支持多继承copy父类

#define GW_CodingImplementation \
- (id)initWithCoder:(NSCoder *)decoder \
{ \
if (self = [super init]) { \
[self GW_Decode:decoder rootObj:self]; \
} \
return self; \
} \
\
- (void)encodeWithCoder:(NSCoder *)encoder \
{ \
[self GW_Encode:encoder rootObj:self]; \
}\
- (id)copyWithZone:(NSZone *)zone { return [self GW_Copy:self]; }


@interface NSObject (GW_Model)

#pragma mark json->model 使用注意事项，需要保证属性名称和json里的参数名,参数名类型（array/dictionary/model）一致，否则会解析成null，支持model多继承，对于array／dictionary里包含的model类型，需要将model类名和参数名保持一致，如果要自定义参数名，请用带changeDic参数的方法

//默认支持的array／dictionary中model类名，1.参数名=类名（首字母不区分大小写） 2.类名=参数名+Model 3.其他格式的类名（只针对array／dictionary），需要在changeDic中，添加@{"参数名":"类名",}

/**
 无路径转换，一个命令转换任何格式的json

 @param json json
 @return model
 */
+ (id)GW_JsonToModel:(id)json;

/**
 json->model

 @param json json
 @param keyPath 路径需要用“／”区分
 @return model
 */
+ (id)GW_JsonToModel:(id)json keyPath:(NSString *)keyPath;


/**
 json->model 自定义参数名，命名原则为--参数名：所改变类的类名（只针对数组／字典）

 @param json json
 @param keyPath 路径需要用“／”区分
 @param changeDic model类名称和参数名不一样的，主要针对array/dictionary里泛型获取不到，无法知道array／dictionary里面装的类的名称
 @return model
 */
+ (id)GW_JsonToModel:(id)json keyPath:(NSString *)keyPath changeDic:(NSDictionary<NSString *,Class> *)changeDic;

///////////////////////////////////////////////////////

#pragma mark model->json 支持深层递归 支持多继承 注意事项：model嵌套的model必须实例化，否则解析为null

/**
 model转json

 @param rootObj model本身
 @return json
 */
- (NSString *)GW_ModelToJson:(__kindof NSObject *)rootObj;


/**
 model转NSDictionary

 @param rootObj model本身
 @return NSDictionary
 */
- (NSDictionary *)GW_ModelToDictionary:(__kindof NSObject *)rootObj;


///////////////////////////////////////////////////////

#pragma mark 模型对象序列化 深层递归模型 支持多继承

/**
 model copy

 @param rootObj model本身
 @return model
 */
- (id)GW_Copy:(__kindof NSObject *)rootObj;


/**
 归档

 @param encode encode
 @param rootObj model本身
 */
- (void)GW_Encode:(NSCoder *)encode rootObj:(__kindof NSObject *)rootObj;


/**
 解档

 @param decode decode
 @param rootObj model本身
 */
- (void)GW_Decode:(NSCoder *)decode rootObj:(__kindof NSObject *)rootObj;
@end
