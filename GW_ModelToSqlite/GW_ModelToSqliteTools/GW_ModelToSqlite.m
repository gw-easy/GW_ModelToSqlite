//
//  GW_ModelToSqlite.m
//  GW_ModelToSqlite
//
//  Created by gw on 2018/4/9.
//  Copyright © 2018年 gw. All rights reserved.
//

#import "GW_ModelToSqlite.h"
#import <objc/runtime.h>
#import <objc/message.h>

#import <CommonCrypto/CommonDigest.h>

//SQLITE_HAS_CODEC 是sqlclipher定义的宏
#ifdef SQLITE_HAS_CODEC
#import "sqlite3.h"
#else
#import <sqlite3.h>
#endif

#define SingalSema GW_Sqlite->singal_sema

static NSString *version_Code = @"1.0";
static NSString *saveKey = @"GW_ModelToSqlite_SaveKey";
static NSString *selfID = @"GWID";
static NSString *MAIN_KEY = @"_id";
static NSString *beginSql = @"BEGIN TRANSACTION";
static NSString *commitSql = @"COMMIT";
//数据库
static sqlite3 *GW_SqliteBase;

typedef NS_ENUM(NSInteger,GW_Type) {
    _String,
    _Int,
    _Boolean,
    _Double,
    _Float,
    _Char,
    _Number,
    _Data,
    _Date,
    _Array,
    _Dictionary,
    _MutableArray,
    _MutableDictionary,
};

typedef NS_ENUM(NSInteger,GW_QueryType) {
    _Where,
    _Order,
    _Limit,
    _WhereOrder,
    _WhereLimit,
    _OrderLimit,
    _WhereOrderLimit
};



@interface GW_PropertyType:NSObject
@property (assign, nonatomic, readonly) GW_Type type;
@property (copy, nonatomic, readonly) NSString *proName;
@property (assign, nonatomic, readonly) SEL setter;
@property (assign, nonatomic, readonly) SEL getter;
@end

@implementation GW_PropertyType

- (instancetype)initWithType:(GW_Type)type
                propertyName:(NSString *)property_name
                        name:(NSString *)name {
    if (self = [super init]) {
        _proName = name.mutableCopy;
        _type = type;
        if (property_name.length > 1) {
            _setter = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:",[property_name substringToIndex:1].uppercaseString,[property_name substringFromIndex:1]]);
        }else {
            _setter = NSSelectorFromString([NSString stringWithFormat:@"set%@:",property_name.uppercaseString]);
        }
        _getter = NSSelectorFromString(property_name);
    }
    return self;
}

@end

@interface GW_ModelToSqlite(){
    dispatch_semaphore_t singal_sema;
}
@property (assign, nonatomic) BOOL update;
@property (strong, nonatomic) NSDictionary *propertyDic;
@end
@implementation GW_ModelToSqlite

//单例
static GW_ModelToSqlite *base = nil;
+ (instancetype)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        base = [[super allocWithZone:NULL] init];
    });
    return base;
}

- (id)copy{
    return GW_Sqlite;
}

- (id)mutableCopy{
    return GW_Sqlite;
}


+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    return GW_Sqlite;
}

- (instancetype)init{
    if (self = [super init]) {
        singal_sema = dispatch_semaphore_create(1);
        self.propertyDic = nil;
        self.version = @"1.0";
        self.sqliteMainKey = MAIN_KEY;
        self.update = YES;
    }
    return self;
}

+ (NSString *)dataCachePath:(Class)sClass{
    NSString *mainPathStr = [NSString stringWithFormat:@"%@/Library/Caches/GW_ModelToSqlite/",NSHomeDirectory()];

    if (GW_Sqlite.mainPath && GW_Sqlite.mainPath.length>0) {
        mainPathStr = GW_Sqlite.mainPath;
    }
    NSString *appendP = @"";

    if (sClass) {
        appendP = [self stringExceSelector:@selector(GW_GetSqliteAppendPath) class:sClass];
    }
    
    if ([self isNullStr:appendP] && ![self isNullStr:GW_Sqlite.appendPath]) {
        appendP = GW_Sqlite.appendPath;
    }
    if (![self isNullStr:appendP]) {
        mainPathStr = [mainPathStr stringByAppendingPathComponent:appendP];
        if (![[mainPathStr substringFromIndex:mainPathStr.length-1] isEqualToString:@"/"]) {
            mainPathStr = [mainPathStr stringByAppendingString:@"/"];
        }
    }
    return mainPathStr;
}

+ (GW_Type)parserProTypeWithAttr:(NSString *)attr {
    NSArray * sub_attrs = [attr componentsSeparatedByString:@","];
    NSString * first_sub_attr = sub_attrs.firstObject;
    first_sub_attr = [first_sub_attr substringFromIndex:1];
    GW_Type field_type = _String;
    const char type = *[first_sub_attr UTF8String];
    switch (type) {
        case 'B':
            field_type = _Boolean;
            break;
        case 'c':
        case 'C':
            field_type = _Char;
            break;
        case 's':
        case 'S':
        case 'i':
        case 'I':
        case 'l':
        case 'L':
        case 'q':
        case 'Q':
            field_type = _Int;
            break;
        case 'f':
            field_type = _Float;
            break;
        case 'd':
        case 'D':
            field_type = _Double;
            break;
        default:
            break;
    }
    return field_type;
}

+ (const NSString *)databaseFieldTypeWithType:(GW_Type)type {
    switch (type) {
        case _String:
            return @"TEXT";
        case _Int:
            return @"INTERGER";
        case _Number:
            return @"DOUBLE";
        case _Double:
            return @"DOUBLE";
        case _Float:
            return @"DOUBLE";
        case _Char:
            return @"NVARCHAR";
        case _Boolean:
            return @"INTERGER";
        case _Data:
            return @"BLOB";
        case _Date:
            return @"DOUBLE";
        case _Array:
            return @"BLOB";
        case _Dictionary:
            return @"BLOB";
        case _MutableArray:
            return @"BLOB";
        case _MutableDictionary:
            return @"BLOB";
        default:
            break;
    }
    return @"TEXT";
}


+ (BOOL)insertModel:(id)modelObj{
    if (modelObj) {
        return [self insertArrayModel:@[modelObj]];
    }
    return NO;
}

+ (BOOL)insertArrayModel:(NSArray *)modelArr{
    [self clearPropertyDicData];
    __block BOOL result = NO;
    dispatch_semaphore_wait(SingalSema, DISPATCH_TIME_FOREVER);
    @autoreleasepool{
        if (modelArr && modelArr.count>0) {
            [self updateTableColumn:[modelArr.firstObject class]];
            if ([self openTable:[modelArr.firstObject class]]) {
                [self execSql:beginSql];
                [modelArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    result = [self commonInsert:obj];
                    if (!result) {
                        *stop = YES;
                    }
                }];
                [self execSql:commitSql];
                [self close];
            }
        }
    }
    dispatch_semaphore_signal(SingalSema);
    return result;
}



+ (BOOL)openTable:(Class)class{
    
    NSString *cachePath = [self dataCachePath:class];
    [self createDirectory:cachePath];
    NSString *version = version_Code;
    if (![self isNullStr:GW_Sqlite.version]) {
        version = GW_Sqlite.version;
        if (GW_Sqlite.update) {
            NSString *localFileName = [self getLocalModelPath:class isPath:NO];
            if (![self isNullStr:localFileName] && [localFileName rangeOfString:version].location == NSNotFound) {
                //更新数据库
                @autoreleasepool{
                    [self updateTableFieldWithModel:class
                                         newVersion:version
                                     localModelName:localFileName];
                }
                
            }
        }
        GW_Sqlite.update = YES;
    }
    NSString *tablePath = [NSString stringWithFormat:@"%@%@_v%@.sqlite",cachePath,NSStringFromClass(class),version];
    if (sqlite3_open([tablePath UTF8String], &GW_SqliteBase) == SQLITE_OK) {
        [self decryptionSqlite];
        return [self createTable:class];
    }
    
    return NO;
}


//创建表
+ (BOOL)createTable:(Class)class{
    NSString *tableName = [self getTableName:class];

    NSDictionary *field_dic = [self getPropertyDicDataClass:class];

    if (field_dic && field_dic.count>0) {
        NSString *main_sKey = [self getMainKey:class];
        __block NSString * createTableSql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,",tableName,main_sKey];
        [field_dic enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull key, GW_PropertyType*  _Nonnull proType, BOOL * _Nonnull stop) {
            createTableSql = [createTableSql stringByAppendingFormat:@"%@ %@ DEFAULT ",key, [self databaseFieldTypeWithType:proType.type]];
            switch (proType.type) {
                case _Data:
                case _String:
                case _Char:
                case _Dictionary:
                case _Array:
                case _MutableArray:
                case _MutableDictionary:
                    createTableSql = [createTableSql stringByAppendingString:@"NULL,"];
                    break;
                case _Boolean:
                case _Int:
                    createTableSql = [createTableSql stringByAppendingString:@"0,"];
                    break;
                case _Float:
                case _Double:
                case _Number:
                case _Date:
                    createTableSql = [createTableSql stringByAppendingString:@"0.0,"];
                    break;
                default:
                    break;
            }
        }];
        
        createTableSql = [createTableSql substringWithRange:NSMakeRange(0, createTableSql.length - 1)];
        createTableSql = [createTableSql stringByAppendingString:@")"];
        
        return [self execSql:createTableSql];
        
    }
    
    return NO;
}

//整理插入语句，绑定数据
+ (BOOL)commonInsert:(id)modelObj {
    sqlite3_stmt *pp_stmt = nil;
    NSDictionary *propertyDic = [self getPropertyDicDataClass:[modelObj class]];
    
    
    NSString *tabName = [self getTableName:[modelObj class]];
    __block NSString * insert_sql = [NSString stringWithFormat:@"INSERT INTO %@ (",tabName];
    NSArray *propertyArr = propertyDic.allKeys;
    NSMutableArray *valueArr = [NSMutableArray array];
    NSMutableArray *insertArr = [NSMutableArray array];
    [propertyArr enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL * _Nonnull stop) {
        GW_PropertyType * proType = propertyDic[key];
        [insertArr addObject:key];
        insert_sql = [insert_sql stringByAppendingFormat:@"%@,",key];
        id value = nil;
        if ([key rangeOfString:@"$"].location == NSNotFound) {
            value = [modelObj valueForKey:key];
        }else {
            value = [modelObj valueForKeyPath:[key stringByReplacingOccurrencesOfString:@"$" withString:@"."]];
            if (!value) {
                switch (proType.type) {
                    case _MutableDictionary:
                        value = [NSMutableDictionary dictionary];
                        break;
                    case _MutableArray:
                        value = [NSMutableArray array];
                        break;
                    case _Dictionary:
                        value = [NSDictionary dictionary];
                        break;
                    case _Array:
                        value = [NSArray array];
                        break;
                    case _Int:
                    case _Float:
                    case _Double:
                    case _Number:
                    case _Char:
                        value = @(0);
                        break;
                    case _Data:
                        value = [NSData data];
                        break;
                    case _Date:
                        value = [NSDate date];
                        break;
                    case _String:
                        value = @"";
                        break;
                    case _Boolean:
                        value = @(NO);
                        break;
                    default:
                        NSLog(@"子模型类数据类型异常并且不能为nil");
                        return;
                }
            }
        }
        if (value) {
            [valueArr addObject:value];
        }else {
            switch (proType.type) {
                case _MutableArray: {
                    NSData *array_value = [NSKeyedArchiver archivedDataWithRootObject:[NSMutableArray array]];
                    [valueArr addObject:array_value];
                }
                    break;
                case _MutableDictionary: {
                    NSData *dictionary_value = [NSKeyedArchiver archivedDataWithRootObject:[NSMutableDictionary dictionary]];
                    [valueArr addObject:dictionary_value];
                }
                    break;
                case _Array: {
                    NSData *array_value = [NSKeyedArchiver archivedDataWithRootObject:[NSArray array]];
                    [valueArr addObject:array_value];
                }
                    break;
                case _Dictionary: {
                    NSData *dictionary_value = [NSKeyedArchiver archivedDataWithRootObject:[NSDictionary dictionary]];
                    [valueArr addObject:dictionary_value];
                }
                    break;
                case _Data: {
                    [valueArr addObject:[NSData data]];
                }
                    break;
                case _String: {
                    [valueArr addObject:@""];
                }
                    break;
                case _Date:
                case _Number: {
                    [valueArr addObject:@(0.0)];
                }
                    break;
                case _Int: {
                    NSNumber *value = @(((int64_t (*)(id, SEL))(void *) objc_msgSend)((id)modelObj, proType.getter));
                    [valueArr addObject:value];
                }
                    break;
                case _Boolean: {
                    NSNumber *value = @(((Boolean (*)(id, SEL))(void *) objc_msgSend)((id)modelObj, proType.getter));
                    [valueArr addObject:value];
                }
                    break;
                case _Char: {
                    NSNumber *value = @(((int8_t (*)(id, SEL))(void *) objc_msgSend)((id)modelObj, proType.getter));
                    [valueArr addObject:value];
                }
                    break;
                case _Double: {
                    NSNumber *value = @(((double (*)(id, SEL))(void *) objc_msgSend)((id)modelObj, proType.getter));
                    [valueArr addObject:value];
                }
                    break;
                case _Float: {
                    NSNumber *value = @(((float (*)(id, SEL))(void *) objc_msgSend)((id)modelObj, proType.getter));
                    [valueArr addObject:value];
                }
                    break;
                default:
                    break;
            }
        }
    }];
    
    insert_sql = [insert_sql substringWithRange:NSMakeRange(0, insert_sql.length - 1)];
    insert_sql = [insert_sql stringByAppendingString:@") VALUES ("];
    
    [propertyArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        insert_sql = [insert_sql stringByAppendingString:@"?,"];
    }];
    insert_sql = [insert_sql substringWithRange:NSMakeRange(0, insert_sql.length - 1)];
    insert_sql = [insert_sql stringByAppendingString:@")"];
    
    if (sqlite3_prepare_v2(GW_SqliteBase, [insert_sql UTF8String], -1, &pp_stmt, nil) == SQLITE_OK) {
        [propertyArr enumerateObjectsUsingBlock:^(NSString *  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
            GW_PropertyType *pro_type = propertyDic[key];
            id value = valueArr[idx];
            int index = (int)[insertArr indexOfObject:key] + 1;
            switch (pro_type.type) {
                case _MutableDictionary:
                case _MutableArray:
                case _Dictionary:
                case _Array: {
                    @try {
                        if ([value isKindOfClass:[NSArray class]] ||
                            [value isKindOfClass:[NSDictionary class]]) {
                            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
                            sqlite3_bind_blob(pp_stmt, index, [data bytes], (int)[data length], SQLITE_TRANSIENT);
                        }else {
                            sqlite3_bind_blob(pp_stmt, index, [value bytes], (int)[value length], SQLITE_TRANSIENT);
                        }
                    } @catch (NSException *exception) {
                        NSLog(@"insert 异常 Array/Dictionary类型元素未实现NSCoding协议归档失败");
                    }
                }
                    break;
                case _Data:
                    sqlite3_bind_blob(pp_stmt, index, [value bytes], (int)[value length], SQLITE_TRANSIENT);
                    break;
                case _String:
                    if ([value respondsToSelector:@selector(UTF8String)]) {
                        sqlite3_bind_text(pp_stmt, index, [value UTF8String], -1, SQLITE_TRANSIENT);
                    }else {
                        sqlite3_bind_text(pp_stmt, index, [[NSString stringWithFormat:@"%@",value] UTF8String], -1, SQLITE_TRANSIENT);
                    }
                    break;
                case _Number:
                    sqlite3_bind_double(pp_stmt, index, [value doubleValue]);
                    break;
                case _Int:
                    sqlite3_bind_int64(pp_stmt, index, (sqlite3_int64)[value longLongValue]);
                    break;
                case _Boolean:
                    sqlite3_bind_int(pp_stmt, index, [value boolValue]);
                    break;
                case _Char:
                    sqlite3_bind_int(pp_stmt, index, [value intValue]);
                    break;
                case _Float:
                    sqlite3_bind_double(pp_stmt, index, [value floatValue]);
                    break;
                case _Double:
                    sqlite3_bind_double(pp_stmt, index, [value doubleValue]);
                    break;
                case _Date: {
                    if ([value isKindOfClass:[NSDate class]]) {
                        sqlite3_bind_double(pp_stmt, index, [(NSDate *)value timeIntervalSince1970]);
                    }else {
                        sqlite3_bind_double(pp_stmt, index, [value doubleValue]);
                    }
                }
                    break;
                default:
                    break;
            }
        }];
        sqlite3_step(pp_stmt);
        sqlite3_finalize(pp_stmt);
    }else {
        NSLog(@"Sorry存储数据失败,建议检查模型类属性类型是否符合规范");
        return NO;
    }
    return YES;
}

//整理model属性／类型／值等属性
+(NSDictionary *)parserSubModelObjectAttributesAndName:(Class)class propertyName:(NSString *)propertyName complete:(void(^)(NSString * key, GW_PropertyType *propertyObj))complete {
    
    BOOL isDicSave = !propertyName && !complete;
    NSMutableDictionary *muDic = isDicSave?[[NSMutableDictionary alloc] init]:nil;
    Class superClass = class_getSuperclass(class);
    if (superClass && superClass != [NSObject class]) {
        NSDictionary *superDic = [self parserSubModelObjectAttributesAndName:superClass propertyName:propertyName complete:complete];
        if (isDicSave) {
            [muDic setValuesForKeysWithDictionary:superDic];
        }
    }
    
    SEL selector = @selector(GW_IgnorePropertyArray);
    NSArray * ignore_propertys;
    if ([class respondsToSelector:selector]) {
        IMP sqlite_info_func = [class methodForSelector:selector];
        NSArray * (*func)(id, SEL) = (void *)sqlite_info_func;
        ignore_propertys = func(class, selector);
    }
    
    unsigned int count = 0;
    objc_property_t *propertyes = class_copyPropertyList(class, &count);
    for (unsigned int i = 0; i<count; i++) {
        objc_property_t property = propertyes[i];
        const char *name = property_getName(property);
        NSString *nameStr = [NSString stringWithUTF8String:name];
 
        if ((ignore_propertys && [ignore_propertys containsObject:nameStr]) || [nameStr isEqualToString:selfID] || [nameStr isEqualToString:[self getMainKey:class]]) {
            continue;
        }
        
        const char *attr = property_getAttributes(property);
        NSString *attrStr = [NSString stringWithUTF8String:attr];
        NSArray *attrArr = [attrStr componentsSeparatedByString:@"\""];
        if (nameStr.length > 1) {
            if (![class instancesRespondToSelector:NSSelectorFromString([NSString stringWithFormat:@"set%@%@:",[nameStr substringToIndex:1].uppercaseString,[nameStr substringFromIndex:1]])]) {
                continue;
            }
        }else {
            if (![class instancesRespondToSelector:NSSelectorFromString([NSString stringWithFormat:@"set%@:",nameStr.uppercaseString])]) {
                continue;
            }
        }
        
        NSString *sName = nameStr;
        if (!isDicSave) {
            sName = [NSString stringWithFormat:@"%@$%@",propertyName,nameStr];
        }
        
        GW_PropertyType *proType = nil;
        if (attrArr.count == 1) {
            // base type
            GW_Type type = [self parserProTypeWithAttr:attrArr[0]];
            proType = [[GW_PropertyType alloc] initWithType:type propertyName:nameStr name:sName];
        }else {
            // refernece type
            Class class_type = NSClassFromString(attrArr[1]);
            if (class_type == [NSNumber class]) {
                proType = [[GW_PropertyType alloc] initWithType:_Number propertyName:nameStr name:sName];
            }else if (class_type == [NSString class]) {
                proType = [[GW_PropertyType alloc] initWithType:_String propertyName:nameStr name:sName];
            }else if (class_type == [NSData class]) {
                proType = [[GW_PropertyType alloc] initWithType:_Data propertyName:nameStr name:sName];
            }else if (class_type == [NSArray class]) {
                proType = [[GW_PropertyType alloc] initWithType:_Array propertyName:nameStr name:sName];
            }else if (class_type == [NSDictionary class]) {
                proType = [[GW_PropertyType alloc] initWithType:_Dictionary propertyName:nameStr name:sName];
            }else if (class_type == [NSDate class]) {
                proType = [[GW_PropertyType alloc] initWithType:_Date propertyName:nameStr name:sName];
            }else if (class_type == [NSMutableArray class]){
                proType = [[GW_PropertyType alloc] initWithType:_MutableArray propertyName:nameStr name:sName];
            }else if (class_type == [NSMutableDictionary class]){
                proType = [[GW_PropertyType alloc] initWithType:_MutableDictionary propertyName:nameStr name:sName];
            }else if (class_type == [NSSet class] ||
                      class_type == [NSValue class] ||
                      class_type == [NSError class] ||
                      class_type == [NSURL class] ||
                      class_type == [NSStream class] ||
                      class_type == [NSScanner class] ||
                      class_type == [NSException class] ||
                      class_type == [NSBundle class]) {
                NSLog(@"model中包含不支持的数据类型");
            }else {
                if (isDicSave) {
                    [self parserSubModelObjectAttributesAndName:class_type propertyName:sName complete:^(NSString *key, GW_PropertyType *propertyObj) {
                        [muDic setObject:propertyObj forKey:key];
                    }];
                }else {
                    [self parserSubModelObjectAttributesAndName:class_type propertyName:sName complete:complete];
                }
            }
        }
        
        if (isDicSave && proType) {
            [muDic setObject:proType forKey:sName];
        }
        if (proType && complete) {
            complete(sName,proType);
        }
    }
    free(propertyes);
    return muDic;
}

#pragma mark update--
+ (BOOL)update:(Class)sClass value:(NSString *)value where:(NSString *)where{
    if (!sClass) {
        return NO;
    }
    [self clearPropertyDicData];
    BOOL result = YES;
    if ([self getLocalModelPath:sClass isPath:NO]) {
        dispatch_semaphore_wait(SingalSema, DISPATCH_TIME_FOREVER);
        @autoreleasepool {
            if (![self isNullStr:value]) {
                [self updateTableColumn:sClass];
                if ([self openTable:sClass]) {
                    NSString * table_name = [self getTableName:sClass];
                    NSString * update_sql = [NSString stringWithFormat:@"UPDATE %@ SET %@",table_name,value];
                    if (where != nil && where.length > 0) {
                        update_sql = [update_sql stringByAppendingFormat:@" WHERE %@", [self handleWhere:where]];
                    }
                    result = [self execSql:update_sql];
                    [self close];
                }else {
                    result = NO;
                }
            }else {
                result = NO;
            }
        }
        dispatch_semaphore_signal(SingalSema);
    }else {
        result = NO;
    }
    return result;
}

+ (BOOL)update:(id)modelObj where:(NSString *)where{
    BOOL result = NO;
    [self clearPropertyDicData];
    if ([self getLocalModelPath:[modelObj class] isPath:NO]) {
        dispatch_semaphore_wait(SingalSema, DISPATCH_TIME_FOREVER);
        @autoreleasepool {
            result = [self updateModel:modelObj where:where];
        }
        dispatch_semaphore_signal(SingalSema);
    }else {
        result = NO;
    }
    return result;
}



+ (BOOL)updateModel:(id)modelObj where:(NSString *)where{
    if (!modelObj){
        return NO;
    }
    Class model_class = [modelObj class];
    
    [self updateTableColumn:model_class];
    
    if (![self openTable:model_class]){
        return NO;
    }

    sqlite3_stmt *pp_stmt = nil;
    NSDictionary *propertyDic = [self getPropertyDicDataClass:model_class];
    NSString *table_name = [self getTableName:model_class];
    
    __block NSString *update_sql = [NSString stringWithFormat:@"UPDATE %@ SET ",table_name];
    
    NSArray *propertyArr = propertyDic.allKeys;
    NSMutableArray *updatePropertyArr = [NSMutableArray array];
    
    [propertyArr enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        update_sql = [update_sql stringByAppendingFormat:@"%@ = ?,",key];
        [updatePropertyArr addObject:key];
    }];
    update_sql = [update_sql substringWithRange:NSMakeRange(0, update_sql.length - 1)];
    if (![self isNullStr:where]) {
        update_sql = [update_sql stringByAppendingFormat:@" WHERE %@", [self handleWhere:where]];
    }
    
    if (sqlite3_prepare_v2(GW_SqliteBase, [update_sql UTF8String], -1, &pp_stmt, nil) == SQLITE_OK) {
        [propertyArr enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
            GW_PropertyType *proType = propertyDic[key];
            id current_model_object = modelObj;
            NSString *actual_field = key;
            if ([key rangeOfString:@"$"].location != NSNotFound) {
                NSString * handle_field_name = [key stringByReplacingOccurrencesOfString:@"$" withString:@"."];
                NSRange backwards_range = [handle_field_name rangeOfString:@"." options:NSBackwardsSearch];
                NSString * key_path = [handle_field_name substringWithRange:NSMakeRange(0, backwards_range.location)];
                current_model_object = [modelObj valueForKeyPath:key_path];
                actual_field = [handle_field_name substringFromIndex:backwards_range.location + backwards_range.length];
            }
            int index = (int)[updatePropertyArr indexOfObject:key] + 1;
            switch (proType.type) {
                case _MutableDictionary:
                case _MutableArray: {
                    id value = [current_model_object valueForKey:actual_field];
                    if (value == nil) {
                        value = proType.type == _MutableDictionary ? [NSMutableDictionary dictionary] : [NSMutableArray array];
                    }
                    @try {
                        NSData * set_value = [NSKeyedArchiver archivedDataWithRootObject:value];
                        sqlite3_bind_blob(pp_stmt, index, [set_value bytes], (int)[set_value length], SQLITE_TRANSIENT);
                    } @catch (NSException *exception) {
                        NSLog(@"update 操作异常 Array/Dictionary 元素没实现NSCoding协议归档失败");
                    }
                }
                    break;
                case _Dictionary:
                case _Array: {
                    id value = [current_model_object valueForKey:actual_field];
                    if (value == nil) {
                        value = proType.type == _Dictionary ? [NSDictionary dictionary] : [NSArray array];
                    }
                    @try {
                        NSData * set_value = [NSKeyedArchiver archivedDataWithRootObject:value];
                        sqlite3_bind_blob(pp_stmt, index, [set_value bytes], (int)[set_value length], SQLITE_TRANSIENT);
                    } @catch (NSException *exception) {
                        NSLog(@"update 操作异常 Array/Dictionary 元素没实现NSCoding协议归档失败");
                    }
                }
                    break;
                case _Date: {
                    NSDate * value = [current_model_object valueForKey:actual_field];
                    if (value == nil) {
                        sqlite3_bind_double(pp_stmt, index, 0.0);
                    }else {
                        sqlite3_bind_double(pp_stmt, index, [value timeIntervalSince1970]);
                    }
                }
                    break;
                case _Data: {
                    NSData * value = [current_model_object valueForKey:actual_field];
                    if (value == nil) {
                        value = [NSData data];
                    }
                    sqlite3_bind_blob(pp_stmt, index, [value bytes], (int)[value length], SQLITE_TRANSIENT);
                }
                    break;
                case _String: {
                    NSString * value = [current_model_object valueForKey:actual_field];
                    if (value == nil) {
                        value = @"";
                    }
                    if ([value respondsToSelector:@selector(UTF8String)]) {
                        sqlite3_bind_text(pp_stmt, index, [value UTF8String], -1, SQLITE_TRANSIENT);
                    }else {
                        sqlite3_bind_text(pp_stmt, index, [[NSString stringWithFormat:@"%@",value] UTF8String], -1, SQLITE_TRANSIENT);
                    }
                }
                    break;
                case _Number: {
                    NSNumber * value = [current_model_object valueForKey:actual_field];
                    if (value == nil) {
                        value = @(0.0);
                    }
                    sqlite3_bind_double(pp_stmt, index, [value doubleValue]);
                }
                    break;
                case _Int: {
                    /* 32bit os type issue
                     long value = ((long (*)(id, SEL))(void *) objc_msgSend)((id)sub_model_object, property_info.getter);*/
                    NSNumber * value = [current_model_object valueForKey:actual_field];
                    sqlite3_bind_int64(pp_stmt, index, (sqlite3_int64)[value longLongValue]);
                }
                    break;
                case _Char: {
                    char value = ((char (*)(id, SEL))(void *) objc_msgSend)((id)current_model_object, proType.getter);
                    sqlite3_bind_int(pp_stmt, index, value);
                }
                    break;
                case _Float: {
                    float value = ((float (*)(id, SEL))(void *) objc_msgSend)((id)current_model_object, proType.getter);
                    sqlite3_bind_double(pp_stmt, index, value);
                }
                    break;
                case _Double: {
                    double value = ((double (*)(id, SEL))(void *) objc_msgSend)((id)current_model_object, proType.getter);
                    sqlite3_bind_double(pp_stmt, index, value);
                }
                    break;
                case _Boolean: {
                    BOOL value = ((BOOL (*)(id, SEL))(void *) objc_msgSend)((id)current_model_object, proType.getter);
                    sqlite3_bind_int(pp_stmt, index, value);
                }
                    break;
                default:
                    break;
            }
        }];
        sqlite3_step(pp_stmt);
        sqlite3_finalize(pp_stmt);
    }else {
        NSLog(@"updata 更新失败");
        [self close];
        return NO;
    }
    [self close];
    return YES;
}

+ (void)updateTableColumn:(Class)sClass{
    if (sClass) {
        NSString *version = version_Code;
        if (![self isNullStr:GW_Sqlite.version]) {
            version = GW_Sqlite.version;
        }
        NSString *localFileName = [self getLocalModelPath:sClass isPath:NO];
        [self updateTableField:sClass newVersion:version localModelName:localFileName];
    }
}

+ (void)updateTableField:(Class)sClass
                       newVersion:(NSString *)newVersion
                   localModelName:(NSString *)local_model_name{

    NSString * table_name = [self getTableName:sClass];
    NSString * cache_directory = [self dataCachePath:sClass];
    NSString * database_cache_path = [NSString stringWithFormat:@"%@%@",cache_directory,local_model_name];
    if (sqlite3_open([database_cache_path UTF8String], &GW_SqliteBase) == SQLITE_OK) {
        [self decryptionSqlite];
        NSArray * old_model_field_name_array = [self getModelFieldNameWithClass:sClass];
        NSDictionary * new_model_info = [self getPropertyDicDataClass:sClass];
        NSMutableString * delete_field_names = [NSMutableString string];
        NSMutableString * add_field_names = [NSMutableString string];
        [old_model_field_name_array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (new_model_info[obj] == nil) {
                [delete_field_names appendString:obj];
                [delete_field_names appendString:@","];
            }
        }];
        [new_model_info enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, GW_PropertyType *obj, BOOL * _Nonnull stop) {
            if (![old_model_field_name_array containsObject:key]) {
                [add_field_names appendFormat:@"%@ %@,",key,[self databaseFieldTypeWithType:obj.type]];
            }
        }];
        if (add_field_names.length > 0) {
            NSArray * add_field_name_array = [add_field_names componentsSeparatedByString:@","];
            [add_field_name_array enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.length > 0) {
                    NSString * add_field_name_sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD %@",table_name,obj];
                    [self execSql:add_field_name_sql];
                }
            }];
        }
        if (delete_field_names.length > 0) {
            [delete_field_names deleteCharactersInRange:NSMakeRange(delete_field_names.length - 1, 1)];
            NSString * default_key = [self getMainKey:sClass];
            if (![default_key isEqualToString:delete_field_names]) {
                GW_Sqlite.update = NO;
                NSArray * old_model_data_array = [self commonQuery:sClass conditions:@[@""] queryType:_Where];
                [self close];
                NSFileManager * file_manager = [NSFileManager defaultManager];
                NSString * file_path = [self getLocalModelPath:sClass isPath:YES];
                if (file_path) {
                    [file_manager removeItemAtPath:file_path error:nil];
                }
                
                if ([self openTable:sClass]) {
                    [self execSql:beginSql];
                    [old_model_data_array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        [self commonInsert:obj];
                    }];
                    [self execSql:commitSql];
                    [self close];
                    return;
                }
            }
        }
        [self close];
    }
    
}

+ (void)updateTableFieldWithModel:(Class)sClass
                       newVersion:(NSString *)newVersion
                   localModelName:(NSString *)local_model_name {
    
    [self updateTableField:sClass newVersion:newVersion localModelName:local_model_name];
    NSString * table_name = [self getTableName:sClass];
    NSString * cache_directory = [self dataCachePath:sClass];
    NSString * database_cache_path = [NSString stringWithFormat:@"%@%@",cache_directory,local_model_name];
    NSString * new_database_cache_path = [NSString stringWithFormat:@"%@%@_v%@.sqlite",cache_directory,table_name,newVersion];
    NSFileManager * file_manager = [NSFileManager defaultManager];
    [file_manager moveItemAtPath:database_cache_path toPath:new_database_cache_path error:nil];

}

+ (NSArray *)getModelFieldNameWithClass:(Class)sClass {
    NSMutableArray * field_name_array = [NSMutableArray array];
    if (GW_SqliteBase) {
        NSString *sql = [NSString stringWithFormat:@"pragma table_info ('%@')",[self getTableName:sClass]];
        sqlite3_stmt *pp_stmt;
        if(sqlite3_prepare_v2(GW_SqliteBase, [sql UTF8String], -1, &pp_stmt, NULL) == SQLITE_OK){
            while(sqlite3_step(pp_stmt) == SQLITE_ROW) {
                int cols = sqlite3_column_count(pp_stmt);
                if (cols > 1) {
                    NSString *name = [NSString stringWithCString:(const char *)sqlite3_column_text(pp_stmt, 1) encoding:NSUTF8StringEncoding];
                    [field_name_array addObject:name];
                }
            }
            sqlite3_finalize(pp_stmt);
        }
    }
    return field_name_array;
}

#pragma mark query--

+ (NSUInteger)count:(Class)sClass{
    NSNumber * count = [self query:sClass func:@"count(*)"];
    return count ? count.unsignedIntegerValue : 0;
}

+ (NSArray *)query:(Class)sClass{
    return [self query:sClass where:nil];
}

+ (NSArray *)query:(Class)sClass where:(NSString *)where{
    return [self queryModel:sClass conditions:@[[self isNullStr:where] ? @"" : where] queryType:_Where];
}

+ (NSArray *)query:(Class)sClass order:(NSString *)order{
    return [self queryModel:sClass conditions:@[order == nil ? @"" : order] queryType:_Order];
}


+ (NSArray *)query:(Class)sClass limit:(NSString *)limit{
    return [self queryModel:sClass conditions:@[limit == nil ? @"" : limit] queryType:_Limit];
}

+ (NSArray *)query:(Class)sClass where:(NSString *)where order:(NSString *)order{
    return [self queryModel:sClass conditions:@[where == nil ? @"" : where,
                                                     order == nil ? @"" : order] queryType:_WhereOrder];
}

+ (NSArray *)query:(Class)sClass where:(NSString *)where limit:(NSString *)limit{
    return [self queryModel:sClass conditions:@[where == nil ? @"" : where,
                                                     limit == nil ? @"" : limit] queryType:_WhereLimit];
}

+ (NSArray *)query:(Class)sClass order:(NSString *)order limit:(NSString *)limit{
    return [self queryModel:sClass conditions:@[order == nil ? @"" : order,
                                                     limit == nil ? @"" : limit] queryType:_OrderLimit];
}

+ (NSArray *)query:(Class)sClass where:(NSString *)where order:(NSString *)order limit:(NSString *)limit{
    return [self queryModel:sClass conditions:@[where == nil ? @"" : where,
                                                     order == nil ? @"" : order,
                                                     limit == nil ? @"" : limit] queryType:_WhereOrderLimit];
}

+ (NSArray *)query:(Class)sClass sql:(NSString *)sql{
    if (sql && sql.length > 0) {
        if (![self getLocalModelPath:sClass isPath:NO]){
            return @[];
        }
        [self clearPropertyDicData];
        dispatch_semaphore_wait(SingalSema, DISPATCH_TIME_FOREVER);
        if (![self openTable:sClass]) return @[];
        NSArray * model_object_array = [self startSqlQuery:sClass sql:sql];
        [self close];
        dispatch_semaphore_signal(SingalSema);
        return model_object_array;
    }
    NSLog(@"sql 查询语句不能为空");
    return @[];
}

+ (id)query:(Class)sClass func:(NSString *)func{
    return [self query:sClass func:func condition:nil];
}

+ (id)query:(Class)sClass func:(NSString *)func condition:(NSString *)condition {
    if (![self getLocalModelPath:sClass isPath:NO]){
        return nil;
    }
    [self clearPropertyDicData];
    dispatch_semaphore_wait(SingalSema, DISPATCH_TIME_FOREVER);
    if (![self openTable:sClass]){
        return @[];
    }
    NSMutableArray * result_array = [NSMutableArray array];
    @autoreleasepool {
        NSString * table_name = [self getTableName:sClass];
        if ([self isNullStr:func]) {
            NSLog(@"发现错误 Sqlite Func 不能为空");
            return nil;
        }
        if ([self isNullStr:condition]) {
            condition = @"";
        }else {
            condition = [self handleWhere:condition];
        }
        NSString * select_sql = [NSString stringWithFormat:@"SELECT %@ FROM %@ %@",func,table_name,condition];
        sqlite3_stmt * pp_stmt = nil;
        if (sqlite3_prepare_v2(GW_SqliteBase, [select_sql UTF8String], -1, &pp_stmt, nil) == SQLITE_OK) {
            int colum_count = sqlite3_column_count(pp_stmt);
            while (sqlite3_step(pp_stmt) == SQLITE_ROW) {
                NSMutableArray * row_result_array = [NSMutableArray array];
                for (int column = 0; column < colum_count; column++) {
                    int column_type = sqlite3_column_type(pp_stmt, column);
                    switch (column_type) {
                        case SQLITE_INTEGER: {
                            sqlite3_int64 value = sqlite3_column_int64(pp_stmt, column);
                            [row_result_array addObject:@(value)];
                        }
                            break;
                        case SQLITE_FLOAT: {
                            double value = sqlite3_column_double(pp_stmt, column);
                            [row_result_array addObject:@(value)];
                        }
                            break;
                        case SQLITE_TEXT: {
                            const unsigned char * text = sqlite3_column_text(pp_stmt, column);
                            if (text != NULL) {
                                NSString * value = [NSString stringWithCString:(const char *)text encoding:NSUTF8StringEncoding];
                                [row_result_array addObject:value];
                            }
                        }
                            break;
                        case SQLITE_BLOB: {
                            int length = sqlite3_column_bytes(pp_stmt, column);
                            const void * blob = sqlite3_column_blob(pp_stmt, column);
                            if (blob != NULL) {
                                NSData * value = [NSData dataWithBytes:blob length:length];
                                [row_result_array addObject:value];
                            }
                        }
                            break;
                        default:
                            break;
                    }
                }
                if (row_result_array.count > 0) {
                    [result_array addObject:row_result_array];
                }
            }
            sqlite3_finalize(pp_stmt);
        }else {
            NSLog(@"Sorry 查询失败, 建议检查sqlite 函数书写格式是否正确！");
        }
        [self close];
        if (result_array.count > 0) {
            NSMutableDictionary * handle_result_dict = [NSMutableDictionary dictionary];
            [result_array enumerateObjectsUsingBlock:^(NSArray * row_result_array, NSUInteger idx, BOOL * _Nonnull stop) {
                [row_result_array enumerateObjectsUsingBlock:^(id _Nonnull column_value, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSString * column_array_key = @(idx).stringValue;
                    NSMutableArray * column_value_array = handle_result_dict[column_array_key];
                    if (!column_value_array) {
                        column_value_array = [NSMutableArray array];
                        handle_result_dict[column_array_key] = column_value_array;
                    }
                    [column_value_array addObject:column_value];
                }];
            }];
            NSArray * all_keys = handle_result_dict.allKeys;
            NSArray * handle_column_array_key = [all_keys sortedArrayUsingComparator:^NSComparisonResult(NSString * key1, NSString * key2) {
                NSComparisonResult result = [key1 compare:key2];
                return result == NSOrderedDescending ? NSOrderedAscending : result;
            }];
            [result_array removeAllObjects];
            if (handle_column_array_key) {
                [handle_column_array_key enumerateObjectsUsingBlock:^(NSString * key, NSUInteger idx, BOOL * _Nonnull stop) {
                    [result_array addObject:handle_result_dict[key]];
                }];
            }
        }
    }
    dispatch_semaphore_signal(SingalSema);
    if (result_array.count == 1) {
        NSArray * element = result_array.firstObject;
        if (element.count > 1){
            return element;
        }
        return element.firstObject;
    }else if (result_array.count > 1) {
        return result_array;
    }
    return nil;
}



+ (NSArray *)queryModel:(Class)sClass conditions:(NSArray *)conditions queryType:(GW_QueryType)query_type{
    if (![self getLocalModelPath:sClass isPath:NO]){
        return @[];
    }
    [self clearPropertyDicData];
    dispatch_semaphore_wait(SingalSema, DISPATCH_TIME_FOREVER);
    NSArray * model_array = [self startQuery:sClass conditions:conditions queryType:query_type];
    dispatch_semaphore_signal(SingalSema);
    return model_array;
}

+ (NSArray *)startQuery:(Class)sClass conditions:(NSArray *)conditions queryType:(GW_QueryType)query_type{
    if (![self openTable:sClass]) return @[];
    NSArray * model_object_array = [self commonQuery:sClass conditions:conditions queryType:query_type];
    [self close];
    return model_object_array;
}

+ (NSArray *)commonQuery:(Class)sClass conditions:(NSArray *)conditions queryType:(GW_QueryType)query_type {
    NSString * table_name = [self getTableName:sClass];
    NSString * select_sql = [NSString stringWithFormat:@"SELECT * FROM %@",table_name];
    NSString * where = nil;
    NSString * order = nil;
    NSString * limit = nil;
    if (conditions && conditions.count > 0) {
        switch (query_type) {
            case _Where: {
                where = [self handleWhere:conditions.firstObject];
                if (![self isNullStr:where]) {
                    select_sql = [select_sql stringByAppendingFormat:@" WHERE %@",where];
                }
            }
                break;
            case _Order: {
                order = [conditions.firstObject stringByReplacingOccurrencesOfString:@"." withString:@"$"];
                if (![self isNullStr:order]) {
                    select_sql = [select_sql stringByAppendingFormat:@" ORDER %@",order];
                }
            }
                break;
            case _Limit:
                limit = [conditions.firstObject stringByReplacingOccurrencesOfString:@"." withString:@"$"];
                if (![self isNullStr:limit]) {
                    select_sql = [select_sql stringByAppendingFormat:@" LIMIT %@",limit];
                }
                break;
            case _WhereOrder: {
                if (conditions.count > 0) {
                    where = [self handleWhere:conditions.firstObject];
                    if (![self isNullStr:where]) {
                        select_sql = [select_sql stringByAppendingFormat:@" WHERE %@",where];
                    }
                }
                if (conditions.count > 1) {
                    order = [conditions.lastObject stringByReplacingOccurrencesOfString:@"." withString:@"$"];
                    if (![self isNullStr:order]) {
                        select_sql = [select_sql stringByAppendingFormat:@" ORDER %@",order];
                    }
                }
            }
                break;
            case _WhereLimit: {
                if (conditions.count > 0) {
                    where = [self handleWhere:conditions.firstObject];
                    if (![self isNullStr:where]) {
                        select_sql = [select_sql stringByAppendingFormat:@" WHERE %@",where];
                    }
                }
                if (conditions.count > 1) {
                    limit = [conditions.lastObject stringByReplacingOccurrencesOfString:@"." withString:@"$"];
                    if (![self isNullStr:limit]) {
                        select_sql = [select_sql stringByAppendingFormat:@" LIMIT %@",limit];
                    }
                }
            }
                break;
            case _OrderLimit: {
                if (conditions.count > 0) {
                    order = [conditions.firstObject stringByReplacingOccurrencesOfString:@"." withString:@"$"];
                    if (![self isNullStr:order]) {
                        select_sql = [select_sql stringByAppendingFormat:@" ORDER %@",order];
                    }
                }
                if (conditions.count > 1) {
                    limit = [conditions.lastObject stringByReplacingOccurrencesOfString:@"." withString:@"$"];
                    if (![self isNullStr:limit]) {
                        select_sql = [select_sql stringByAppendingFormat:@" LIMIT %@",limit];
                    }
                }
            }
                break;
            case _WhereOrderLimit: {
                if (conditions.count > 0) {
                    where = [self handleWhere:conditions.firstObject];
                    if (![self isNullStr:where]) {
                        select_sql = [select_sql stringByAppendingFormat:@" WHERE %@",where];
                    }
                }
                if (conditions.count > 1) {
                    order = [conditions[1] stringByReplacingOccurrencesOfString:@"." withString:@"$"];
                    if (![self isNullStr:order]) {
                        select_sql = [select_sql stringByAppendingFormat:@" ORDER %@",order];
                    }
                }
                if (conditions.count > 2) {
                    limit = [conditions.lastObject stringByReplacingOccurrencesOfString:@"." withString:@"$"];
                    if (![self isNullStr:limit]) {
                        select_sql = [select_sql stringByAppendingFormat:@" LIMIT %@",limit];
                    }
                }
            }
                break;
            default:
                break;
        }
    }
    return [self startSqlQuery:sClass sql:select_sql];
}

+ (NSArray *)startSqlQuery:(Class)sClass sql:(NSString *)sql{
    NSDictionary * field_dictionary = [self getPropertyDicDataClass:sClass];
    NSMutableArray * model_object_array = [NSMutableArray array];
    sqlite3_stmt * pp_stmt = nil;
    if (sqlite3_prepare_v2(GW_SqliteBase, [sql UTF8String], -1, &pp_stmt, nil) == SQLITE_OK) {
        int colum_count = sqlite3_column_count(pp_stmt);
        while (sqlite3_step(pp_stmt) == SQLITE_ROW) {
            id model_object = [self autoNewSubmodelWithClass:sClass];
            if (!model_object) {
                break;
            }
            SEL GWIDsel = NSSelectorFromString([NSString stringWithFormat:@"set%@",selfID]);
            SEL custom_id_sel = nil;
            NSString * custom_id_key = [self getMainKey:sClass];
            if (custom_id_key && custom_id_key.length > 0) {
                if (custom_id_key.length > 1) {
                    custom_id_sel = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:",[custom_id_key substringToIndex:1].uppercaseString,[custom_id_key substringFromIndex:1]]);
                }else {
                    custom_id_sel = NSSelectorFromString([NSString stringWithFormat:@"set%@:",custom_id_key.uppercaseString]);
                }
            }
            if (custom_id_sel && [model_object respondsToSelector:custom_id_sel]) {
                sqlite3_int64 value = sqlite3_column_int64(pp_stmt, 0);
                ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id)model_object, custom_id_sel, value);
            }
            if ([model_object respondsToSelector:GWIDsel]) {
                sqlite3_int64 value = sqlite3_column_int64(pp_stmt, 0);
                ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id)model_object, GWIDsel, value);
            }
            for (int column = 1; column < colum_count; column++) {
                NSString *field_name = [NSString stringWithCString:sqlite3_column_name(pp_stmt, column) encoding:NSUTF8StringEncoding];
                GW_PropertyType *property_info = field_dictionary[field_name];
                if (!property_info){
                    continue;
                }
                id current_model_object = model_object;
                if ([field_name rangeOfString:@"$"].location != NSNotFound) {
                    NSString * handle_field_name = [field_name stringByReplacingOccurrencesOfString:@"$" withString:@"."];
                    NSRange backwards_range = [handle_field_name rangeOfString:@"." options:NSBackwardsSearch];
                    NSString * key_path = [handle_field_name substringWithRange:NSMakeRange(0, backwards_range.location)];
                    current_model_object = [model_object valueForKeyPath:key_path];
                    field_name = [handle_field_name substringFromIndex:backwards_range.length + backwards_range.location];
                    if (!current_model_object) continue;
                }
                switch (property_info.type) {
                    case _MutableArray:
                    case _MutableDictionary:
                    case _Dictionary:
                    case _Array: {
                        int length = sqlite3_column_bytes(pp_stmt, column);
                        const void * blob = sqlite3_column_blob(pp_stmt, column);
                        if (blob != NULL) {
                            NSData * value = [NSData dataWithBytes:blob length:length];
                            @try {
                                id set_value = [NSKeyedUnarchiver unarchiveObjectWithData:value];
                                if (set_value) {
                                    switch (property_info.type) {
                                        case _MutableArray:
                                            if ([set_value isKindOfClass:[NSArray class]]) {
                                                set_value = [NSMutableArray arrayWithArray:set_value];
                                            }
                                            break;
                                        case _MutableDictionary:
                                            if ([set_value isKindOfClass:[NSDictionary class]]) {
                                                set_value = [NSMutableDictionary dictionaryWithDictionary:set_value];
                                            }
                                            break;
                                        default:
                                            break;
                                    }
                                    [current_model_object setValue:set_value forKey:field_name];
                                }
                            } @catch (NSException *exception) {
                                NSLog(@"query 查询异常 Array/Dictionary 元素没实现NSCoding协议解归档失败");
                            }
                        }
                    }
                        break;
                    case _Date: {
                        double value = sqlite3_column_double(pp_stmt, column);
                        if (value > 0) {
                            NSDate * date_value = [NSDate dateWithTimeIntervalSince1970:value];
                            if (date_value) {
                                [current_model_object setValue:date_value forKey:field_name];
                            }
                        }
                    }
                        break;
                    case _Data: {
                        int length = sqlite3_column_bytes(pp_stmt, column);
                        const void * blob = sqlite3_column_blob(pp_stmt, column);
                        if (blob != NULL) {
                            NSData * value = [NSData dataWithBytes:blob length:length];
                            [current_model_object setValue:value forKey:field_name];
                        }
                    }
                        break;
                    case _String: {
                        const unsigned char * text = sqlite3_column_text(pp_stmt, column);
                        if (text != NULL) {
                            NSString * value = [NSString stringWithCString:(const char *)text encoding:NSUTF8StringEncoding];
                            [current_model_object setValue:value forKey:field_name];
                        }
                    }
                        break;
                    case _Number: {
                        double value = sqlite3_column_double(pp_stmt, column);
                        [current_model_object setValue:@(value) forKey:field_name];
                    }
                        break;
                    case _Int: {
                        sqlite3_int64 value = sqlite3_column_int64(pp_stmt, column);
                        ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id)current_model_object, property_info.setter, value);
                    }
                        break;
                    case _Float: {
                        double value = sqlite3_column_double(pp_stmt, column);
                        ((void (*)(id, SEL, float))(void *) objc_msgSend)((id)current_model_object, property_info.setter, value);
                    }
                        break;
                    case _Double: {
                        double value = sqlite3_column_double(pp_stmt, column);
                        ((void (*)(id, SEL, double))(void *) objc_msgSend)((id)current_model_object, property_info.setter, value);
                    }
                        break;
                    case _Char: {
                        int value = sqlite3_column_int(pp_stmt, column);
                        ((void (*)(id, SEL, int))(void *) objc_msgSend)((id)current_model_object, property_info.setter, value);
                    }
                        break;
                    case _Boolean: {
                        int value = sqlite3_column_int(pp_stmt, column);
                        ((void (*)(id, SEL, int))(void *) objc_msgSend)((id)current_model_object, property_info.setter, value);
                    }
                        break;
                    default:
                        break;
                }
            }
            [model_object_array addObject:model_object];
        }
    }else {
        NSLog(@"Sorry查询语句异常,建议检查查询条件Sql语句语法是否正确");
    }
    sqlite3_finalize(pp_stmt);
    return model_object_array;
}

+ (id)autoNewSubmodelWithClass:(Class)sClass{
    if (sClass) {
        id model = sClass.new;
        unsigned int property_count = 0;
        objc_property_t * propertys = class_copyPropertyList(sClass, &property_count);
        for (int i = 0; i < property_count; i++) {
            objc_property_t property = propertys[i];
            const char * property_attributes = property_getAttributes(property);
            NSString * property_attributes_string = [NSString stringWithUTF8String:property_attributes];
            NSArray * property_attributes_list = [property_attributes_string componentsSeparatedByString:@"\""];
            if (property_attributes_list.count > 1) {
                // refernece type
                Class class_type = NSClassFromString(property_attributes_list[1]);
                if ([self isSubModelWithClass:class_type]) {
                    const char * property_name = property_getName(property);
                    NSString * property_name_string = [NSString stringWithUTF8String:property_name];
                    [model setValue:[self autoNewSubmodelWithClass:class_type] forKey:property_name_string];
                }
            }
        }
        free(propertys);
        return model;
    }
    return nil;
}

#pragma mark delete--
+ (BOOL)delete_class:(Class)sClass{
    return [self delete_class:sClass where:nil];
}

+ (BOOL)delete_class:(Class)sClass where:(NSString *)where{
    BOOL result = YES;
    
    dispatch_semaphore_wait(SingalSema, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        result = [self commonDeleteModel:sClass where:where];
    }
    dispatch_semaphore_signal(SingalSema);
    return result;
}

+ (BOOL)commonDeleteModel:(Class)sClass where:(NSString *)where{
    BOOL result = YES;
    [self clearPropertyDicData];
    if ([self getLocalModelPath:sClass isPath:NO]) {
        if ([self openTable:sClass]) {
            NSString * table_name = [self getTableName:sClass];
            NSString * delete_sql = [NSString stringWithFormat:@"DELETE FROM %@",table_name];
            if (where != nil && where.length > 0) {
                delete_sql = [delete_sql stringByAppendingFormat:@" WHERE %@",[self handleWhere:where]];
            }
            result = [self execSql:delete_sql];
            [self close];
        }else {
            result = NO;
        }
    }else {
        result = NO;
    }
    return result;
}

#pragma mark remove--
+ (void)removeAllTable{
    dispatch_semaphore_wait(SingalSema, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        NSFileManager * file_manager = [NSFileManager defaultManager];
        NSString * cache_path = [self dataCachePath: nil];
        BOOL is_directory = YES;
        if ([file_manager fileExistsAtPath:cache_path isDirectory:&is_directory]) {
            NSArray * file_array = [file_manager contentsOfDirectoryAtPath:cache_path error:nil];
            [file_array enumerateObjectsUsingBlock:^(id  _Nonnull file, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![file isEqualToString:@".DS_Store"]) {
                    NSString * file_path = [NSString stringWithFormat:@"%@%@",cache_path,file];
                    [file_manager removeItemAtPath:file_path error:nil];
                    NSLog(@"%@",[NSString stringWithFormat:@"已经删除了数据库 ->%@",file_path]);
                }
            }];
        }
    }
    dispatch_semaphore_signal(SingalSema);
}

+ (void)removeTable:(Class)sClass{
    dispatch_semaphore_wait(SingalSema, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        NSFileManager * file_manager = [NSFileManager defaultManager];
        NSString * file_path = [self getLocalModelPath:sClass isPath:YES];
        if (file_path) {
            [file_manager removeItemAtPath:file_path error:nil];
        }
    }
    dispatch_semaphore_signal(SingalSema);
}

+ (NSString *)localPathWithModel:(Class)sClass{
    return [self getLocalModelPath:sClass isPath:YES];
}

+ (NSString *)versionWithModel:(Class)sClass{
    NSString * model_version = nil;
    NSString * model_name = [self getLocalModelPath:sClass isPath:NO];
    if (model_name) {
        NSRange end_range = [model_name rangeOfString:@"." options:NSBackwardsSearch];
        NSRange start_range = [model_name rangeOfString:@"v" options:NSBackwardsSearch];
        if (end_range.location != NSNotFound &&
            start_range.location != NSNotFound) {
            model_version = [model_name substringWithRange:NSMakeRange(start_range.length + start_range.location, end_range.location - (start_range.length + start_range.location))];
        }
    }
    return model_version;
}

+ (BOOL)isSubModelWithClass:(Class)sClass{
    return (sClass != [NSString class] &&
            sClass != [NSNumber class] &&
            sClass != [NSArray class] &&
            sClass != [NSSet class] &&
            sClass != [NSData class] &&
            sClass != [NSDate class] &&
            sClass != [NSDictionary class] &&
            sClass != [NSValue class] &&
            sClass != [NSError class] &&
            sClass != [NSURL class] &&
            sClass != [NSStream class] &&
            sClass != [NSURLRequest class] &&
            sClass != [NSURLResponse class] &&
            sClass != [NSBundle class] &&
            sClass != [NSScanner class] &&
            sClass != [NSException class]);
}

+ (NSString *)handleWhere:(NSString *)where{
    NSString * where_string = @"";
    if (![self isNullStr:where]) {
        NSArray * where_list = [where componentsSeparatedByString:@" "];
        NSMutableString * handle_where = [NSMutableString string];
        [where_list enumerateObjectsUsingBlock:^(NSString * sub_where, NSUInteger idx, BOOL * _Nonnull stop) {
            NSRange dot_range = [sub_where rangeOfString:@"."];
            if (dot_range.location != NSNotFound &&
                ![sub_where hasPrefix:@"'"] &&
                ![sub_where hasSuffix:@"'"]) {
                
                __block BOOL has_number = NO;
                NSArray * dot_sub_list = [sub_where componentsSeparatedByString:@"."];
                [dot_sub_list enumerateObjectsUsingBlock:^(NSString * dot_string, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSString * before_char = nil;
                    if (dot_string.length > 0) {
                        before_char = [dot_string substringToIndex:1];
                        if ([self isNumber:before_char]) {
                            has_number = YES;
                            *stop = YES;
                        }
                    }
                }];
                if (!has_number) {
                    [handle_where appendFormat:@"%@ ",[sub_where stringByReplacingOccurrencesOfString:@"." withString:@"$"]];
                }else {
                    [handle_where appendFormat:@"%@ ",sub_where];
                }
            }else {
                [handle_where appendFormat:@"%@ ",sub_where];
            }
        }];
        if ([handle_where hasSuffix:@" "]) {
            [handle_where deleteCharactersInRange:NSMakeRange(handle_where.length - 1, 1)];
        }
        return handle_where;
    }
    return where_string;
}

+ (BOOL)isNumber:(NSString *)cahr {
    int value;
    NSScanner *scan = [NSScanner scannerWithString:cahr];
    return [scan scanInt:&value] && [scan isAtEnd];
}

//执行语句
+ (BOOL)execSql:(NSString *)sql{
    BOOL result = sqlite3_exec(GW_SqliteBase, [sql UTF8String], nil, nil, nil)==SQLITE_OK;
    if (!result) {
        NSLog(@"执行失败->%@",sql);
    }
    return result;
}

//获取表名
+ (NSString *)getTableName:(Class)class{
    NSString *tabName = [self stringExceSelector:@selector(GW_GetTableName) class:class];
    if (![self isNullStr:tabName]) {
        return tabName;
    }
    if (![self isNullStr:GW_Sqlite.tableName]) {
        return GW_Sqlite.tableName;
    }
    return NSStringFromClass(class);
}

//关闭数据库
+ (void)close{
    if (GW_SqliteBase) {
        sqlite3_close(GW_SqliteBase);
        GW_SqliteBase = nil;
    }
}

//数据库加密
+ (void)decryptionSqlite{
#ifdef SQLITE_HAS_CODEC
    if (![self isNullStr:GW_Sqlite.sqlitePassword]) {
        NSString *oldPass = [self passwordWithSqlite];
        BOOL UpdatePass = (oldPass && ![oldPass isEqualToString:GW_Sqlite.sqlitePassword]);
        if (![self setPassKey:UpdatePass?oldPass:GW_Sqlite.sqlitePassword]) {
            //建议使用pod导入
            NSLog(@"数据库加密失败, 请引入SQLCipher库");
        }else{
            if (UpdatePass) {
                [self resetPassKey:GW_Sqlite.sqlitePassword];
            }
        }
    }
#endif
}

+ (NSString *)getLocalModelPath:(Class)class isPath:(BOOL)isPath {
    NSString *className = NSStringFromClass(class);
    NSString *filePath = [self dataCachePath:class];
    __block NSString *localPath = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        NSArray<NSString *> *pathArr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil];
        [pathArr enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj rangeOfString:className].location != NSNotFound){
                if (isPath) {
                    localPath = [NSString stringWithFormat:@"%@%@",filePath,obj];
                }else {
                    localPath = [obj mutableCopy];
                }
                *stop = YES;
            }
        }];
    }
    return localPath;
}

//设置密码
+ (BOOL)setPassKey:(NSString *)key{
    NSData *keyData = [NSData dataWithBytes:[key UTF8String] length:(NSUInteger)strlen([key UTF8String])];
#ifdef SQLITE_HAS_CODEC
    if (!keyData) {
        return NO;
    }
    int result = sqlite3_key(GW_SqliteBase, [keyData bytes], (int)[keyData length]);
    return (result == SQLITE_OK);
#else
    return NO;
#endif
}

//重置密码
+ (BOOL)resetPassKey:(NSString *)key{
    NSData *keyData = [NSData dataWithBytes:[key UTF8String] length:(NSUInteger)strlen([key UTF8String])];
#ifdef SQLITE_HAS_CODEC
    if (!keyData) {
        return NO;
    }
    int result = sqlite3_rekey(GW_SqliteBase, [keyData bytes], (int)[keyData length]);
    return (result == SQLITE_OK);
#else
    return NO;
#endif
}

//获取加密密码
+ (NSString *)passwordWithSqlite{
    NSString *password = nil;
    NSData * p_data = [[NSUserDefaults standardUserDefaults] objectForKey:saveKey];
    if (p_data) {
        password = [[NSString alloc] initWithData:p_data encoding:NSUTF8StringEncoding];
    }
    
    return password;
}

//保存加密密码
+(void)savePasswordwithSqlite:(NSString *)key{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSData *p_data = [key dataUsingEncoding:NSUTF8StringEncoding];
        [[NSUserDefaults standardUserDefaults] setObject:p_data forKey:saveKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    });
}


+ (NSString *)getMainKey:(Class)class{
    NSString *mainKey = [self stringExceSelector:@selector(GW_GetSqliteMainKey) class:class];
    if (![self isNullStr:mainKey]) {
        return mainKey;
    }
    if (![self isNullStr:GW_Sqlite.sqliteMainKey]) {
        return GW_Sqlite.sqliteMainKey;
    }
    return MAIN_KEY;
}

+ (NSArray *)arrayExceSelector:(SEL)selector class:(Class)class {
    if ([class respondsToSelector:selector]) {
        IMP sqlite_info_func = [class methodForSelector:selector];
        NSArray * (*func)(id, SEL) = (void *)sqlite_info_func;
        return func(class, selector);
    }
    return nil;
}

+ (NSString *)stringExceSelector:(SEL)selector class:(Class)class {
    if ([class respondsToSelector:selector]) {
        IMP sqlite_info_func = [class methodForSelector:selector];
        NSString * (*func)(id, SEL) = (void *)sqlite_info_func;
        return func(class, selector);
    }
    return nil;
}

//创建文件夹
+ (void)createDirectory:(NSString *)path{
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}
//创建文件
+ (void)createPath:(NSString *)path{
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
    }
}

//判断是否是空字符
+ (BOOL)isNullStr:(NSString *)aStr{
    if (!aStr) {
        return YES;
    }
    if (!aStr.length) {
        return YES;
    }
    if ([aStr isKindOfClass:[NSNull class]]) {
        return YES;
    }
    return NO;
}

+ (NSDictionary *)getPropertyDicDataClass:(Class)class{
    if (!GW_Sqlite.propertyDic || GW_Sqlite.propertyDic.count==0) {
        GW_Sqlite.propertyDic = [self parserSubModelObjectAttributesAndName:class propertyName:nil complete:nil];
    }
    return GW_Sqlite.propertyDic;
}

//清理数据
+ (void)clearPropertyDicData{
    if (GW_Sqlite.propertyDic && GW_Sqlite.propertyDic.count >0) {
        GW_Sqlite.propertyDic = nil;
    }
}
@end
