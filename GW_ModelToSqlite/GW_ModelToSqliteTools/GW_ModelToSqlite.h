//
//  GW_ModelToSqlite.h
//  GW_ModelToSqlite
//
//  Created by gw on 2018/4/9.
//  Copyright © 2018年 gw. All rights reserved.
//

#import <Foundation/Foundation.h>
#define GW_Sqlite [GW_ModelToSqlite shareInstance]

@protocol GW_ModelToSqliteDelegate<NSObject>
@optional
//获取model需要存储的拼接位置（只是拼接路径，不需要添加主路径）
+(NSString *)GW_GetSqliteAppendPath;
//获取model自定义主键
+(NSString *)GW_GetSqliteMainKey;
//获取不需要存储的属性，以提高存储效率，（数组内装属性名）
+(NSArray *)GW_IgnorePropertyArray;
//获取此model类，需要和其他表名关联（如果只是临时需要调用一次，建议使用下面的属性tableName）
+ (NSString *)GW_GetTableName;
@end

@interface GW_ModelToSqlite : NSObject

//表名称 （非model类名+_V+版本号），（临时修改表名，需要修改此项，读取／存储完毕后，需要手动置nil）
@property (copy, nonatomic) NSString *tableName;

//表版本号 默认是1.0（全局）建议在应用启动阶段就配置好，修改相当于整个数据库版本更新，请慎重
@property (copy, nonatomic) NSString *version;

//加密需要引用SQLCipher三方库(建议用pod导入，省去很多麻烦的配置)（全局）建议在应用启动阶段就配置好
@property (copy, nonatomic) NSString *sqlitePassword;

//主键 默认是_id （全局设置主键，如果实现代理，以代理主键为优先，建议不要轻易修改）
@property (copy, nonatomic) NSString *sqliteMainKey;

#pragma mark 路径 注意事项：路径一定要在存储之前设定好
//存储主路径（表存储路径）默认：NSHomeDirectory()/Library/Caches/GW_ModelToSqlite/,
@property (copy, nonatomic) NSString *mainPath;

//拼接路径（全局路径，如果和代理拼接路径同时存在，以代理路径为准）（可以将表添加到主路径下其他路径，根据需要添加）默认是nil，
@property (copy, nonatomic) NSString *appendPath;

+ (instancetype)shareInstance;

//完整的存储路径（主路径+拼接路径）
+ (NSString *)dataCachePath:(Class)Class;

#pragma mark 注意事项：当model里面有array／dictionary存有对象时，需保证里面的对象遵守coding协议
/*
 insert/updata 已经实现自动更新数据库
 */
/**
 * 说明: 存储模型到本地
 * @param modelObj 模型对象
 */

+ (BOOL)insertModel:(id)modelObj;

/**
 * 说明: 存储模型数组到本地(事务方式)
 * @param modelArr 模型数组对象(modelArr 里对象类型要一致)
 */

+ (BOOL)insertArrayModel:(NSArray *)modelArr;

/**
 * 说明: 更新本地模型对象
 * @param modelObj 模型对象
 * @param where 查询条件(查询语法和SQL where 查询语法一样，where为空则更新所有)
 */
+ (BOOL)update:(id)modelObj where:(NSString *)where;

/**
 说明: 更新数据表字段
 
 @param sClass 模型类
 @param value 更新的值
 @param where 更新条件
 @return 是否成功
 /// 更新Person表在age字段大于25岁是的name值为YJ，age为100岁
 /// example: [GW_ModelToSqlite update:Person.self value:@"name = 'YJ', age = 100" where:@"age > 25"];
 */
+ (BOOL)update:(Class)sClass value:(NSString *)value where:(NSString *)where;


/**
 * 说明: 获取模型类表总条数
 * @param sClass 模型类
 * @return 总条数
 */
+ (NSUInteger)count:(Class)sClass;

/**
 * 说明: 查询本地模型对象
 * @param sClass 模型类
 * @return 查询模型对象数组
 */

+ (NSArray *)query:(Class)sClass;

/**
 * 说明: 查询本地模型对象
 * @param sClass 模型类
 * @param where 查询条件(查询语法和SQL where 查询语法一样，where为空则查询所有)
 * @return 查询模型对象数组
 */

+ (NSArray *)query:(Class)sClass where:(NSString *)where;

/**
 * 说明: 查询本地模型对象
 * @param model_class 模型类
 * @param order 排序条件(排序语法和SQL order 查询语法一样，order为空则不排序)
 * @return 查询模型对象数组
 */

/// example: [GW_ModelToSqlite query:[Person class] order:@"by age desc/asc"];
/// desc降序，asc升序
/// 对person数据表查询并且根据age自动降序或者升序排序

+ (NSArray *)query:(Class)sClass order:(NSString *)order;

/**
 * 说明: 查询本地模型对象
 * @param model_class 模型类
 * @param limit 限制条件(限制语法和SQL limit 查询语法一样，limit为空则不限制查询)
 * @return 查询模型对象数组
 */

/// example: [GW_ModelToSqlite query:[Person class] limit:@"8"];
/// 对person数据表查询并且并且限制查询数量为8
/// example: [GW_ModelToSqlite query:[Person class] limit:@"8 offset 8"];
/// 对person数据表查询并且对查询列表偏移8并且限制查询数量为8

+ (NSArray *)query:(Class)sClass limit:(NSString *)limit;

/**
 * 说明: 查询本地模型对象
 * @param model_class 模型类
 * @param where 查询条件(查询语法和SQL where 查询语法一样，where为空则查询所有)
 * @param order 排序条件(排序语法和SQL order 查询语法一样，order为空则不排序)
 * @return 查询模型对象数组
 */

/// example: [GW_ModelToSqlite query:[Person class] where:@"age < 30" order:@"by age desc/asc"];
/// 对person数据表查询age小于30岁并且根据age自动降序或者升序排序

+ (NSArray *)query:(Class)sClass where:(NSString *)where order:(NSString *)order;

/**
 * 说明: 查询本地模型对象
 * @param model_class 模型类
 * @param where 查询条件(查询语法和SQL where 查询语法一样，where为空则查询所有)
 * @param limit 限制条件(限制语法和SQL limit 查询语法一样，limit为空则不限制查询)
 * @return 查询模型对象数组
 */

/// example: [GW_ModelToSqlite query:[Person class] where:@"age <= 30" limit:@"8"];
/// 对person数据表查询age小于30岁并且限制查询数量为8
/// example: [GW_ModelToSqlite query:[Person class] where:@"age <= 30" limit:@"8 offset 8"];
/// 对person数据表查询age小于30岁并且对查询列表偏移8并且限制查询数量为8

+ (NSArray *)query:(Class)sClass where:(NSString *)where limit:(NSString *)limit;

/**
 * 说明: 查询本地模型对象
 * @param model_class 模型类
 * @param order 排序条件(排序语法和SQL order 查询语法一样，order为空则不排序)
 * @param limit 限制条件(限制语法和SQL limit 查询语法一样，limit为空则不限制查询)
 * @return 查询模型对象数组
 */

/// example: [GW_ModelToSqlite query:[Person class] order:@"by age desc/asc" limit:@"8"];
/// 对person数据表查询并且根据age自动降序或者升序排序并且限制查询的数量为8
/// example: [GW_ModelToSqlite query:[Person class] order:@"by age desc/asc" limit:@"8 offset 8"];
/// 对person数据表查询并且根据age自动降序或者升序排序并且限制查询的数量为8偏移为8

+ (NSArray *)query:(Class)sClass order:(NSString *)order limit:(NSString *)limit;

/**
 * 说明: 查询本地模型对象
 * @param model_class 模型类
 * @param where 查询条件(查询语法和SQL where 查询语法一样，where为空则查询所有)
 * @param order 排序条件(排序语法和SQL order 查询语法一样，order为空则不排序)
 * @param limit 限制条件(限制语法和SQL limit 查询语法一样，limit为空则不限制查询)
 * @return 查询模型对象数组
 */

/// example: [GW_ModelToSqlite query:[Person class] where:@"age <= 30" order:@"by age desc/asc" limit:@"8"];
/// 对person数据表查询age小于30岁并且根据age自动降序或者升序排序并且限制查询的数量为8
/// example: [GW_ModelToSqlite query:[Person class] where:@"age <= 30" order:@"by age desc/asc" limit:@"8 offset 8"];
/// 对person数据表查询age小于30岁并且根据age自动降序或者升序排序并且限制查询的数量为8偏移为8

+ (NSArray *)query:(Class)sClass where:(NSString *)where order:(NSString *)order limit:(NSString *)limit;


/**
 说明: 自定义sql查询
 
 @param sClass 接收model类
 @param sql sql语句
 @return 查询模型对象数组
 
 /// example: [GW_ModelToSqlite query:Model.self sql:@"select cc.* from ( select bb.*,(select count(*)+1 from Chapter where chapter_id = bb.chapter_id and updateTime<bb.updateTime ) as group_id from Chapter bb) cc where cc.group_id<=7 order by updateTime desc"];
 */
+ (NSArray *)query:(Class)sClass sql:(NSString *)sql;

/**
 * 说明: 利用sqlite 函数进行查询
 
 * @param sClass 要查询模型类
 * @param func sqlite函数例如：（MAX(age),MIN(age),COUNT(*)....）
 * @return 返回查询结果(如果结果条数 > 1返回Array , = 1返回单个值 , = 0返回nil)
 * /// example: [GW_ModelToSqlite query:[Person class] sqliteFunc:@"max(age)"];  /// 获取Person表的最大age值
 * /// example: [GW_ModelToSqlite query:[Person class] sqliteFunc:@"count(*)"];  /// 获取Person表的总记录条数
 */
+ (id)query:(Class)sClass func:(NSString *)func;

/**
 * 说明: 利用sqlite 函数进行查询
 
 * @param sClass 要查询模型类
 * @param func sqlite函数例如：（MAX(age),MIN(age),COUNT(*)....）
 * @param condition 其他查询条件例如：(where age > 20 order by age desc ....)
 * @return 返回查询结果(如果结果条数 > 1返回Array , = 1返回单个值 , = 0返回nil)
 * /// example: [GW_ModelToSqlite query:[Person class] sqliteFunc:@"max(age)" condition:@"where name = '北京'"];  /// 获取Person表name=北京集合中的的最大age值
 * /// example: [GW_ModelToSqlite query:[Person class] sqliteFunc:@"count(*)" condition:@"where name = '北京'"];  /// 获取Person表name=北京集合中的总记录条数
 */
+ (id)query:(Class)sClass func:(NSString *)func condition:(NSString *)condition;

/**
 * 说明: 清空本地模型对象
 * @param sClass 模型类
 */

+ (BOOL)delete_class:(Class)sClass;


/**
 * 说明: 删除指定本地模型对象
 * @param sClass 模型类
 * @param where 查询条件(查询语法和SQL where 查询语法一样，where为空则删除所有)
 */

+ (BOOL)delete_class:(Class)sClass where:(NSString *)where;

/**
 * 说明: 清空当前目录下数据库
 */

+ (void)removeAllTable;

/**
 * 说明: 删除当前目录下的表
 * @param sClass 模型类
 */

+ (void)removeTable:(Class)sClass;

/**
 * 说明: 返回本地表的位置
 * @param sClass 模型类
 * @return 路径
 */

+ (NSString *)localPathWithModel:(Class)sClass;

/**
 * 说明: 返回本地表的版本号
 * @param sClass 模型类
 * @return 版本号
 */
+ (NSString *)versionWithModel:(Class)sClass;

@end
