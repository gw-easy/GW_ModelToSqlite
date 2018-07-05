
//  NSObject+GW_Model.m
//  gw_test
//
//  Created by gw on 2018/3/29.
//  Copyright © 2018年 gw. All rights reserved.
//

#import "NSObject+GW_Model.h"
#import <objc/runtime.h>
#import <objc/message.h>
typedef NS_OPTIONS(NSUInteger, GW_Action) {
    _GW_Class_FirstUP,
    _GW_Class_AllUP,
    _GW_Class_Model,
    _GW_SEL_FirstUP,
    _GW_SEL_AllUP
    
};

typedef NS_OPTIONS(NSUInteger, GW_TYPE) {
    _Array = 1 << 0,
    _Dictionary = 1 << 1,
    _String = 1 << 2,
    _Integer = 1 << 3,
    _UInteger = 1 << 4,
    _Float = 1 << 5,
    _Double = 1 << 6,
    _Boolean = 1 << 7,
    _Char = 1 << 8,
    _Number = 1 << 9,
    _Null = 1 << 10,
    _Model = 1 << 11,
    _Data = 1 << 12,
    _Date = 1 << 13,
    _Value = 1 << 14,
    _Url = 1 << 15,
    _Set = 1 << 16,
    _UChar = 1 << 17,
    _Unknown = 1 << 18
};

@interface GW_ModelPropertyType : NSObject
@property (assign, nonatomic) Class class;
@property (assign, nonatomic) GW_TYPE type;
@property (assign, nonatomic) SEL setter;
@property (assign, nonatomic) SEL getter;
@end
@implementation GW_ModelPropertyType

- (void)setClass:(Class)_class valueClass:(Class)valueClass {
    self.class = _class;
    if (self.class == nil) {
        self.type = _Null;
        return;
    }
    if ([self.class isSubclassOfClass:[NSString class]]) {self.type = _String;}
    else if ([self.class isSubclassOfClass:[NSDictionary class]]) {self.type = _Dictionary;}
    else if ([valueClass isSubclassOfClass:[NSDictionary class]]) {self.type = _Model;}
    else if ([self.class isSubclassOfClass:[NSArray class]]) {self.type = _Array;}
    else if ([self.class isSubclassOfClass:[NSNumber class]]) {self.type = _Number;}
    else if ([self.class isSubclassOfClass:[NSDate class]]) {self.type = _Date;}
    else if ([self.class isSubclassOfClass:[NSValue class]]) {self.type = _Value;}
    else if ([self.class isSubclassOfClass:[NSData class]]) {self.type = _Data;}
    else {self.type = _Unknown;}
    
    if (valueClass == [NSNull class]) {
        self.type = _Null;
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.type = _Unknown;
    }
    return self;
}

@end

@implementation NSObject (GW_Model)

- (GW_TYPE)getClass:(Class)class{
    GW_TYPE type = _Null;
    if (class == nil) {
        return _Null;
    }
    if ([class isSubclassOfClass:[NSString class]]) {type = _String;}
    else if ([class isSubclassOfClass:[NSDictionary class]]) {type = _Dictionary;}
    else if ([class isSubclassOfClass:[NSArray class]]) {type = _Array;}
    else if ([class isSubclassOfClass:[NSNumber class]]) {type = _Number;}
    else if ([class isSubclassOfClass:[NSDate class]]) {type = _Date;}
    else if ([class isSubclassOfClass:[NSValue class]]) {type = _Value;}
    else if ([class isSubclassOfClass:[NSData class]]) {type = _Data;}
    else {type = _Model;}
    return type;
}

#pragma mark 模型数据序列化
//归档
- (void)GW_Encode:(NSCoder *)encode rootObj:(__weak __kindof NSObject *)rootObj{
    Class superClass = class_getSuperclass(self.class);
    if (superClass && superClass != [NSObject class]) {
        __kindof NSObject *superObject = superClass.new;
        [superClass GW_EnumeratePropertyNameBlock:^(NSString *propertyName, objc_property_t property, NSInteger index, BOOL *stop) {
            [superObject setValue:[rootObj valueForKey:propertyName] forKey:propertyName];
        }];
        [superObject GW_Encode:encode rootObj:rootObj];
    }
    
    [self.class GW_EnumeratePropertyNameBlock:^(NSString *propertyName, objc_property_t property, NSInteger index, BOOL *stop) {
        id value = [self valueForKey:propertyName];
        if (value) {
            [encode encodeObject:value forKey:propertyName];
        }
    }];
}

//解档
- (void)GW_Decode:(NSCoder *)decode rootObj:(__weak __kindof NSObject *)rootObj{
    Class superClass = class_getSuperclass(self.class);
    if (superClass && superClass != [NSObject class]) {
        __kindof NSObject *superObject = superClass.new;
        [superObject GW_Decode:decode rootObj:rootObj];
        [superClass GW_EnumeratePropertyNameBlock:^(NSString *propertyName, objc_property_t property, NSInteger index, BOOL *stop) {
            [rootObj setValue:[superObject valueForKey:propertyName] forKey:propertyName];
        }];
    }
    
    [self.class GW_EnumeratePropertyNameBlock:^(NSString *propertyName, objc_property_t property, NSInteger index, BOOL *stop) {
        id value = [decode decodeObjectForKey:propertyName];
        [self GW_CopyAndDecoder:value propertyName:propertyName property:property classObject:self isCopy:NO];
    }];
}

//复制
- (id)GW_Copy:(__weak __kindof NSObject *)rootObj{
    id copySelf = self.class.new;
    
    [self.class GW_EnumeratePropertyNameBlock:^(NSString *propertyName, objc_property_t property, NSInteger index, BOOL *stop) {
        [copySelf setValue:[rootObj valueForKey:propertyName] forKey:propertyName];
    }];
    
    [self copySuperObject:copySelf rootObj:rootObj];
    [self.class GW_EnumeratePropertyNameBlock:^(NSString *propertyName, objc_property_t property, NSInteger index, BOOL *stop) {
        id value = [self valueForKey:propertyName];
        [self GW_CopyAndDecoder:value propertyName:propertyName property:property classObject:copySelf isCopy:YES];
    }];
    return copySelf;
}

- (void)copySuperObject:(id)copySelf rootObj:(__weak __kindof NSObject *)rootObj{
    Class superClass = class_getSuperclass(self.class);
    if (superClass && superClass != [NSObject class]) {
        NSObject *superObject = superClass.new;
        [superClass GW_EnumeratePropertyNameBlock:^(NSString *propertyName, objc_property_t property, NSInteger index, BOOL *stop) {
            [superObject setValue:[rootObj valueForKey:propertyName] forKey:propertyName];
            [copySelf setValue:[rootObj valueForKey:propertyName] forKey:propertyName];
        }];
        [superObject copySuperObject:copySelf rootObj:rootObj];
    }
}

#pragma mark 模型对象属性处理
//NS_NOESCAPE和swift的闭包@noescape相呼应，如果闭包能在方法返回之前调用，那么该修饰符可以让编译器做很多优化，比如剔除对 self 的捕获、持有、释放等。

+ (void)GW_EnumeratePropertyNameBlock:(void (NS_NOESCAPE ^)(NSString *propertyName,objc_property_t property,NSInteger index,BOOL *stop))block{
    unsigned int propertyCount = 0;
    BOOL stop = NO;
    objc_property_t *properties = class_copyPropertyList(self, &propertyCount);
    for (unsigned int i = 0; i<propertyCount; i++) {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        block([NSString stringWithUTF8String:name],property,i,&stop);
        if (stop) {
            break;
        }
    }
    free(properties);
}

+ (void)GW_EnumeratePropertyAttributesAndNameBlock:(void (NS_NOESCAPE ^)(NSString *propertyAttribute,NSString *propertyName,objc_property_t property,NSInteger index,BOOL *stop))block{
    unsigned int propertyCount = 0;
    BOOL stop = NO;
    
    objc_property_t *properties = class_copyPropertyList(self, &propertyCount);
    for (unsigned int i = 0; i<propertyCount; i++) {
        objc_property_t property_t = properties[i];
        const char *attributes = property_getAttributes(property_t);
        const char *name = property_getName(property_t);
        NSString *attUT8 = [NSString stringWithUTF8String:attributes];
        NSString *nameStr = [NSString stringWithUTF8String:name];
        NSArray *buteArr = [attUT8 componentsSeparatedByString:@"\""];
        if (buteArr.count != 1) {
            block(buteArr[1],nameStr,property_t,i,&stop);
        }
        if (stop) {
            break;
        }
    }
    free(properties);
}

- (void)GW_CopyAndDecoder:(id)value propertyName:(NSString *)propertyName property:(objc_property_t)property classObject:(id)classObject isCopy:(BOOL)isCopy{
    if (value) {
        
        GW_ModelPropertyType *propertyType = [GW_ModelPropertyType new];
        const char *attributes = property_getAttributes(property);
        propertyType.type = [self.class parserTypeWithAttr:[NSString stringWithUTF8String:attributes]];
        propertyType.setter = [self.class getSELName_FirstUP:propertyName type:_GW_SEL_FirstUP];
        
        
        if ([classObject respondsToSelector:propertyType.setter]) {
//            id value = [self valueForKey:propertyName];
            switch (propertyType.type) {
                case _Char:
                    ((void (*)(id, SEL, char))(void *) objc_msgSend)((id)classObject, propertyType.setter, [value charValue]);
                    break;
                case _Float:
                    ((void (*)(id, SEL, float))(void *) objc_msgSend)((id)classObject, propertyType.setter, [value floatValue]);
                    break;
                case _Double:
                    ((void (*)(id, SEL, double))(void *) objc_msgSend)((id)classObject, propertyType.setter, [value doubleValue]);
                    break;
                case _Boolean:
                    ((void (*)(id, SEL, BOOL))(void *) objc_msgSend)((id)classObject, propertyType.setter, [value boolValue]);
                    break;
                case _Integer:
                    ((void (*)(id, SEL, NSInteger))(void *) objc_msgSend)((id)classObject, propertyType.setter, [value integerValue]);
                    break;
                case _UInteger:
                    ((void (*)(id, SEL, NSUInteger))(void *) objc_msgSend)((id)classObject, propertyType.setter, [value unsignedIntegerValue]);
                    break;
                default:
                    if (isCopy) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)self, propertyType.setter, [value copy]);
                    }else{
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)self, propertyType.setter, value);
                    }
                    
                    break;
            }
        }
    }
}

+ (GW_TYPE)parserTypeWithAttr:(NSString *)attr {
    NSArray * sub_attrs = [attr componentsSeparatedByString:@","];
    NSString * first_sub_attr = sub_attrs.firstObject;
    first_sub_attr = [first_sub_attr substringFromIndex:1];
    GW_TYPE attr_type = _Null;
    const char type = *[first_sub_attr UTF8String];
    switch (type) {
        case 'B':
            attr_type = _Boolean;
            break;
        case 'c':
        case 'C':
            attr_type = _Char;
            break;
        case 'S':
        case 'I':
        case 'L':
        case 'Q':
            attr_type = _UInteger;
        case 'l':
        case 'q':
        case 'i':
        case 's':
            attr_type = _Integer;
            break;
        case 'f':
            attr_type = _Float;
            break;
        case 'd':
        case 'D':
            attr_type = _Double;
            break;
        default:
            break;
    }
    return attr_type;
}

#pragma mark model->json

- (NSString *)GW_ModelToJson:(__kindof NSObject *)rootObj{
    id jsonSet = nil;
    if ([self isKindOfClass:[NSDictionary class]]) {
        jsonSet = [self GW_ParserDictionaryEngine:(NSDictionary *)self rootObj:rootObj];
    }else if ([self isKindOfClass:[NSArray class]]) {
        jsonSet = [self GW_ParserArrayEngine:(NSArray *)self rootObj:rootObj];
    }else {
        jsonSet = [self GW_ModelToDictionary:rootObj];
    }
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:jsonSet options:kNilOptions error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (__kindof NSObject *)getRootObj:(__kindof NSObject *)rootObj superClass:(Class)superClass{
    __block __kindof NSObject *modelObj = nil;
    if (![rootObj isKindOfClass:superClass]) {
        [rootObj.class GW_EnumeratePropertyAttributesAndNameBlock:^(NSString *propertyAttribute, NSString *propertyName, objc_property_t property, NSInteger index, BOOL *stop) {
            Class properClass = NSClassFromString(propertyAttribute);
            if (self.class == properClass) {
                modelObj = [rootObj valueForKey:propertyName];
                *stop = YES;
            }else if ([self getClass:properClass] == _Model){
                modelObj = [self getRootObj:[rootObj valueForKey:propertyName] superClass:superClass];
            }
        }];
    }
    return modelObj;
}

- (NSDictionary *)GW_ModelToDictionary:(__kindof NSObject *)rootObj{
    NSMutableDictionary * jsonDictionary = [NSMutableDictionary new];
    Class superClass = class_getSuperclass(self.class);
    if (superClass &&
        superClass != [NSObject class]) {
        NSObject * superObject = superClass.new;
        
        if (![rootObj isKindOfClass:superClass]) {
            __kindof NSObject *modelObj = [self getRootObj:rootObj superClass:superClass];
            if (modelObj) {
                rootObj = modelObj;
            }
        }
        
        
        [superClass GW_EnumeratePropertyNameBlock:^(NSString *propertyName, objc_property_t property, NSInteger index, BOOL *stop) {
            [superObject setValue:[rootObj valueForKey:propertyName] forKey:propertyName];
        }];
        [jsonDictionary setDictionary:[superObject GW_ModelToDictionary:rootObj]];
    }

    [self.class GW_EnumeratePropertyNameBlock:^(NSString *propertyName, objc_property_t property, NSInteger index, BOOL *stop) {
            const char * attributes = property_getAttributes(property);
            NSArray * attributesArray = [[NSString stringWithUTF8String:attributes] componentsSeparatedByString:@"\""];
            if (attributesArray.count == 1) {
                id value = [self valueForKey:propertyName];
                [jsonDictionary setValue:value forKey:propertyName];
            }else {
                id value = ((id (*)(id, SEL))(void *) objc_msgSend)((id)self, NSSelectorFromString(propertyName));
                
                if (value != nil) {
                    Class classType = NSClassFromString(attributesArray[1]);
                    if ([classType isSubclassOfClass:[NSString class]]) {
                        [jsonDictionary setValue:value forKey:propertyName];
                    }else if ([classType isSubclassOfClass:[NSNumber class]]) {
                        [jsonDictionary setValue:value forKey:propertyName];
                    }else if ([classType isSubclassOfClass:[NSDictionary class]]) {
                        [jsonDictionary setValue:[self GW_ParserDictionaryEngine:value rootObj:rootObj] forKey:propertyName];
                    }else if ([classType isSubclassOfClass:[NSArray class]]) {
                        [jsonDictionary setValue:[self GW_ParserArrayEngine:value rootObj:rootObj] forKey:propertyName];
                    }else if ([classType isSubclassOfClass:[NSDate class]]) {
                        if ([value isKindOfClass:[NSString class]]) {
                            [jsonDictionary setValue:value forKey:propertyName];
                        }else {
                            NSDateFormatter * formatter = [NSDateFormatter new];
                            formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
                            [jsonDictionary setValue:[formatter stringFromDate:value] forKey:propertyName];
                        }
                    }else if ([classType isSubclassOfClass:[NSData class]]) {
                        if ([value isKindOfClass:[NSData class]]) {
                            [jsonDictionary setValue:[[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding] forKey:propertyName];
                        }else {
                            [jsonDictionary setValue:value forKey:propertyName];
                        }
                    }else if ([classType isSubclassOfClass:[NSValue class]] || [classType isSubclassOfClass:[NSSet class]] || [classType isSubclassOfClass:[NSURL class]] || [classType isSubclassOfClass:[NSError class]]) {
                    }else {
                        [jsonDictionary setValue:[value GW_ModelToDictionary:value] forKey:propertyName];
                    }
                }else {
                    [jsonDictionary setValue:[NSNull new] forKey:propertyName];
                }
            }
        
    }];
    return jsonDictionary;
}

#pragma mark - 模型对象转json解析引擎(private) -

- (id)GW_ParserDictionaryEngine:(NSDictionary *)value rootObj:(NSObject *)rootObj{
    if (value == nil) return [NSNull new];
    NSMutableDictionary * subJsonDictionary = [NSMutableDictionary new];
    NSArray * allKey = value.allKeys;
    for (NSString * key in allKey) {
        id subValue = value[key];
        if ([subValue isKindOfClass:[NSString class]] ||
            [subValue isKindOfClass:[NSNumber class]]) {
            [subJsonDictionary setValue:subValue forKey:key];
        }else if ([subValue isKindOfClass:[NSDictionary class]]){
            [subJsonDictionary setValue:[self GW_ParserDictionaryEngine:subValue rootObj:rootObj] forKey:key];
        }else if ([subValue isKindOfClass:[NSArray class]]) {
            [subJsonDictionary setValue:[self GW_ParserArrayEngine:subValue rootObj:rootObj] forKey:key];
        }else {
            [subJsonDictionary setValue:[subValue GW_ModelToDictionary:rootObj] forKey:key];
        }
    }
    return subJsonDictionary;
}

- (id)GW_ParserArrayEngine:(NSArray *)value rootObj:(NSObject *)rootObj{
    if (value == nil) return [NSNull new];
    NSMutableArray * subJsonArray = [NSMutableArray new];
    for (id subValue in value) {
        if ([subValue isKindOfClass:[NSString class]] ||
            [subValue isKindOfClass:[NSNumber class]]) {
            [subJsonArray addObject:subValue];
        }else if ([subValue isKindOfClass:[NSDictionary class]]){
            [subJsonArray addObject:[self GW_ParserDictionaryEngine:subValue rootObj:rootObj]];
        }else if ([subValue isKindOfClass:[NSArray class]]) {
            [subJsonArray addObject:[self GW_ParserArrayEngine:subValue rootObj:rootObj]];
        }else {
            [subJsonArray addObject:[subValue GW_ModelToDictionary:rootObj]];
        }
    }
    return subJsonArray;
}


#pragma json->model

+ (id)GW_JsonToModel:(id)json{
    return [self GW_JsonToModel:json keyPath:nil];
}

+ (id)GW_JsonToModel:(id)json keyPath:(NSString *)keyPath{
    return [self GW_JsonToModel:json keyPath:keyPath changeDic:nil];
}

+ (id)GW_JsonToModel:(id)json keyPath:(NSString *)keyPath changeDic:(NSDictionary<NSString *,Class> *)changeDic{
    if (json) {
        __block id jsonObject = nil;
        if ([json isKindOfClass:[NSData class]]) {
            jsonObject = [NSJSONSerialization JSONObjectWithData:json options:kNilOptions error:nil];
            return [self GW_JsonToModel:jsonObject keyPath:keyPath changeDic:changeDic];
        }else if ([json isKindOfClass:[NSString class]]) {
            jsonObject = [json dataUsingEncoding:NSUTF8StringEncoding];
            return [self GW_JsonToModel:jsonObject keyPath:keyPath changeDic:changeDic];
        }
        
        if ([json isKindOfClass:[NSDictionary class]] || [json isKindOfClass:[NSArray class]]) {
            if (keyPath && keyPath.length>0) {
                jsonObject = json;
                NSArray<NSString *> * keyPathArray = [keyPath componentsSeparatedByString:@"/"];
                [keyPathArray enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
                    jsonObject = jsonObject[key];
                }];
                if (jsonObject) {
                    if ([jsonObject isKindOfClass:[NSDictionary class]] || [jsonObject isKindOfClass:[NSArray class]]) {
                        return [self GW_ModelDataEngine:jsonObject class:self changeDic:changeDic];
                    }else {
                        //路径不正确
                        return jsonObject;
                        
                    }
                }
            }else{
                return [self GW_ModelDataEngine:json class:self changeDic:changeDic];
            }
        }else{
            //json格式不正确
            return nil;
        }
    }
    //没有json
    return nil;
}



+ (id)GW_ModelDataEngine:(id)objc class:(Class)class changeDic:(NSDictionary *)changeDic{
    if ([objc isKindOfClass:[NSDictionary class]]) {
        __block __kindof NSObject *modelObject = nil;
        NSDictionary *objDic = objc;
        if ([class isSubclassOfClass:[NSDictionary class]]) {
            modelObject = [[NSMutableDictionary alloc] init];
            [objDic enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[NSDictionary class]] || [objDic isKindOfClass:[NSArray class]]) {
                    Class subModelClass = NSClassFromString(key);
                    subModelClass = [self GW_HasExistClass:key changeDic:changeDic sub_Class:subModelClass];
                    if (!subModelClass) {
                        subModelClass = [obj class]; 
                    }
                    [modelObject setValue:[self GW_ModelDataEngine:obj class:subModelClass changeDic:changeDic] forKey:key];
                    
                }else{
                    [modelObject setValue:obj forKey:key];
                }
            }];
        }else{
            modelObject = [class new];
            [objDic enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                SEL setter = nil;
                GW_ModelPropertyType *propertyType = nil;

                
//                获取model的类型，是否包含其他mdoel／array／dictionary
                propertyType = [self GW_ModelExistProperty:key withObject:modelObject valueClass:[obj class]];
                
                if(!propertyType){
                    return;
                }
//                NSLog(@"class ==  %@",propertyType.class);
                
                if (key.length > 1) {
                    setter = [self getSELName_FirstUP:key type:_GW_SEL_FirstUP];
                }else {
                    setter = [self getSELName_FirstUP:key type:_GW_SEL_AllUP];
                }
                
                if (![modelObject respondsToSelector:setter]) {
                    key = [self GW_HasExistProperty:key withObject:modelObject];
                    if (!key) {
                        return;
                    }
                    
                    if (key.length > 1) {
                        setter = [self getSELName_FirstUP:key type:_GW_SEL_FirstUP];
                    }else {
                        setter = [self getSELName_FirstUP:key type:_GW_SEL_AllUP];
                    }
                }
                
                propertyType.setter = setter;
                Class sub_Class = NSClassFromString(key);
                switch (propertyType.type) {
                    case _Array:
                        sub_Class = [self GW_HasExistClass:key changeDic:changeDic sub_Class:sub_Class];

                        if (sub_Class) {
                            ((void (*)(id, SEL, NSArray *))(void *) objc_msgSend)((id)modelObject, propertyType.setter, [self GW_ModelDataEngine:obj class:sub_Class changeDic:changeDic]);
                        }else{
                            ((void (*)(id, SEL, NSArray *))(void *) objc_msgSend)((id)modelObject, propertyType.setter, obj);
                        }
                        break;
                    case _Dictionary:
                        sub_Class = [self GW_HasExistClass:key changeDic:changeDic sub_Class:sub_Class];
                       
                        if (sub_Class) {
                            
                            NSMutableDictionary *subDic = [[NSMutableDictionary alloc] init];
                            [obj enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, id  _Nonnull data, BOOL * _Nonnull stop) {
                                [subDic setValue:[self GW_ModelDataEngine:data class:sub_Class changeDic:changeDic] forKey:key];
                            }];
                            ((void (*)(id, SEL, NSDictionary *))(void *) objc_msgSend)((id)modelObject, propertyType.setter, subDic);
                        }else{
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)modelObject, propertyType.setter, obj);
                        }
                        break;
                    case _String:
                        
                        ((void (*)(id, SEL, NSString *))(void *) objc_msgSend)((id)modelObject, propertyType.setter, obj);
                        
                        break;
                    case _Number:
                        
                        ((void (*)(id, SEL, NSNumber *))(void *) objc_msgSend)((id)modelObject, propertyType.setter, obj);
                        
                        break;
                    case _Integer:
                        ((void (*)(id, SEL, NSInteger))(void *) objc_msgSend)((id)modelObject, propertyType.setter, [obj integerValue]);
                        break;
                    case _UInteger:
                        ((void (*)(id, SEL, NSUInteger))(void *) objc_msgSend)((id)modelObject, propertyType.setter, [obj unsignedIntegerValue]);
                        break;
                    case _Boolean:
                        ((void (*)(id, SEL, BOOL))(void *) objc_msgSend)((id)modelObject, propertyType.setter, [obj boolValue]);
                        break;
                    case _Float:
                        ((void (*)(id, SEL, float))(void *) objc_msgSend)((id)modelObject, propertyType.setter, [obj floatValue]);
                        break;
                    case _Double:
                        ((void (*)(id, SEL, double))(void *) objc_msgSend)((id)modelObject, propertyType.setter, [obj doubleValue]);
                        break;
                    case _Char:
                        ((void (*)(id, SEL, int8_t))(void *) objc_msgSend)((id)modelObject, propertyType.setter, (int8_t)[obj charValue]);
                        break;
                    case _UChar:
                        ((void (*)(id, SEL, uint8_t))(void *) objc_msgSend)((id)modelObject, propertyType.setter, (uint8_t)[obj unsignedCharValue]);
                        break;
                    case _Model:
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)modelObject, propertyType.setter, [self GW_ModelDataEngine:obj class:propertyType.class changeDic:changeDic]);
                        break;
                    case _Date:
                        
                        ((void (*)(id, SEL, NSDate *))(void *) objc_msgSend)((id)modelObject, propertyType.setter, obj);
                        
                        break;
                    case _Value:
                        
                        ((void (*)(id, SEL, NSValue *))(void *) objc_msgSend)((id)modelObject, propertyType.setter, obj);
                        
                        break;
                    case _Data: {
                        
                        ((void (*)(id, SEL, NSData *))(void *) objc_msgSend)((id)modelObject, propertyType.setter, obj);
                        
                        break;
                    }
                    case _Null: {
                        
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)modelObject, propertyType.setter, nil);
                        
                        break;
                    }
                    default:
                        break;
                }
            }];
        }
        
        return modelObject;
    }else if([objc isKindOfClass:[NSArray class]]){
        NSMutableArray *modelArray = [NSMutableArray new];
        [objc enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            id subModel = [self GW_ModelDataEngine:obj class:class changeDic:changeDic];
            if (subModel) {
                [modelArray addObject:subModel];
            }
        }];
        return modelArray;
    }else{
        return objc;
    }
}

+ (id)GW_HasExistClass:(NSString *)key changeDic:(NSDictionary *)changeDic sub_Class:(Class)sub_Class{
    __block Class s_class = sub_Class;
    if (!s_class) {
        s_class = [self getClassName_firstUP:key type:_GW_Class_FirstUP];
    }
    
    if (!s_class) {
        s_class = [self getClassName_firstUP:key type:_GW_Class_Model];
    }
    
    if (!s_class) {
        if (changeDic) {
            [changeDic enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull changeKey, Class  _Nonnull changeObj, BOOL * _Nonnull stop) {
                if ([changeKey isEqualToString:key]) {
                    s_class = changeObj;
                }
            }];
        }
    }
    
    if (!s_class) {
        return nil;
    }
    return s_class;
}

+ (NSString *)GW_HasExistProperty:(NSString *)property withObject:(__kindof NSObject *)object{
    objc_property_t property_t = class_getProperty(object.class, [property UTF8String]);
    if (property_t) {
        const char *name = property_getName(property_t);
        NSString *nameStr = [NSString stringWithUTF8String:name];
        return nameStr;
    }else{
        unsigned int count = 0;
        objc_property_t *propertyes = class_copyPropertyList(object.class, &count);
        for (unsigned int i = 0; i<count; i++) {
            objc_property_t property_t = propertyes[i];
            const char *name = property_getName(property_t);
            NSString *nameStr = [NSString stringWithUTF8String:name];
            if ([nameStr.lowercaseString isEqualToString:property.lowercaseString]) {
                free(propertyes);
                return nameStr;
            }
        }
        free(propertyes);
        Class superClass = class_getSuperclass(object.class);
        if (superClass && superClass != [NSObject class]) {
            NSString *name = [self GW_HasExistProperty:property withObject:[superClass new]];
            if (name && name.length>0) {
                return name;
            }
        }
        return nil;
    }
    
}

+ (GW_ModelPropertyType *)GW_ModelExistProperty:(NSString *)property withObject:(__kindof NSObject *)object valueClass:(Class)valueClass {
    GW_ModelPropertyType *propertyType = nil;
    objc_property_t property_t = class_getProperty(object.class, [property UTF8String]);
    if (property_t) {
        const char *attributes = property_getAttributes(property_t);
        NSString *attUT8 = [NSString stringWithUTF8String:attributes];
        NSArray *buteArr = [attUT8 componentsSeparatedByString:@"\""];
        propertyType = [[GW_ModelPropertyType alloc] init];
        if (buteArr.count == 1) {
            propertyType.type = valueClass == [NSNull class]?_Null:[self parserTypeWithAttr:buteArr[0]];
        }else{
            [propertyType setClass:NSClassFromString(buteArr[1]) valueClass:valueClass];
        }
        return propertyType;
    }else{
        unsigned int count = 0;
        objc_property_t *propertyes = class_copyPropertyList([object class], &count);
        for (unsigned int i = 0; i<count; i++) {
            objc_property_t property_t = propertyes[i];
            const char *name = property_getName(property_t);
            NSString *nameStr = [NSString stringWithUTF8String:name];
            if ([nameStr.lowercaseString isEqualToString:property.lowercaseString]) {
                const char *attributes = property_getAttributes(property_t);
                NSString *buteStr = [NSString stringWithUTF8String:attributes];
                NSArray *buteArr = [buteStr componentsSeparatedByString:@"\""];
                free(propertyes);
                propertyType = [[GW_ModelPropertyType alloc] init];
                if (buteArr.count == 1) {
                    propertyType.type = valueClass == [NSNull class]?_Null:[self parserTypeWithAttr:buteArr[0]];
                }else{
                    [propertyType setClass:NSClassFromString(buteArr[1]) valueClass:valueClass];
                }
                return propertyType;
            }
        }
        
        free(propertyes);
        Class superClass = class_getSuperclass([object class]);
        if (superClass && superClass != [NSObject class]) {
            propertyType = [self GW_ModelExistProperty:property withObject:superClass.new valueClass:valueClass];
            if (propertyType) {
                return propertyType;
            }
        }
    }
    return propertyType;
}

+ (Class)getClassName_firstUP:(NSString *)keyName type:(GW_Action)type{
    NSString * first = [keyName substringToIndex:1];
    NSString * other = [keyName substringFromIndex:1];
    switch (type) {
        case _GW_Class_FirstUP:
            return NSClassFromString([NSString stringWithFormat:@"%@%@",[first uppercaseString],other]);
            break;
        case _GW_Class_AllUP:
            
            break;
        case _GW_Class_Model:
            return NSClassFromString([NSString stringWithFormat:@"%@%@Model",first,other]);
            break;
        default:
            break;
    }
    return nil;
}

+ (SEL)getSELName_FirstUP:(NSString *)keyName type:(GW_Action)type{
    NSString * first = [keyName substringToIndex:1];
    NSString * other = [keyName substringFromIndex:1];
    switch (type) {
        case _GW_SEL_FirstUP:
            return NSSelectorFromString([NSString stringWithFormat:@"set%@%@:",first.uppercaseString, other]);
            break;
        case _GW_SEL_AllUP:
            return NSSelectorFromString([NSString stringWithFormat:@"set%@:",keyName.uppercaseString]);
            break;
        default:
            break;
    }
    return nil;
}









@end
