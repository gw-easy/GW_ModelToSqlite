//
//  Test_Model2.m
//  GW_ModelKit
//
//  Created by gw on 2018/4/8.
//  Copyright © 2018年 gw. All rights reserved.
//

#import "Test_Model2.h"

@implementation Test_Model2
+(NSDictionary<NSString *,Class> *)GW_ModelDelegateReplacePropertyMapper{
    return @{@"address":[addressModel class],@"email":[emailModel class],@"formatted_name":[formattedModel class],@"label":[labelModel class],@"name":[nameModel class],@"organization":[orgaModel class],@"telephone":[telephoneModel class],@"title":[titleModel class],@"url":[urlModel class],@"setModel":[Model1 class]};
}

+(void)GW_JsonToModelFinish:(NSObject *)Obj{
    if ([Obj isKindOfClass:[Test_Model2 class]]) {
        Test_Model2 *tModel = (Test_Model2 *)Obj;
        tModel.rotation_angle = @"gw";
    }
}
@end
@implementation itemModel
+ (NSDictionary<NSString *,Class> *)GW_ModelDelegateReplacePropertyMapper{
    return @{@"setModel":[Model1 class]};
}
@end
@implementation addressModel
+ (NSDictionary<NSString *,Class> *)GW_ModelDelegateReplacePropertyMapper{
    return @{@"item":[itemModel class]};
}
@end
@implementation emailModel

@end
@implementation labelModel
+ (NSDictionary<NSString *,Class> *)GW_ModelDelegateReplacePropertyMapper{
    return @{@"item":[itemModel class]};
}
@end
@implementation nameModel
+ (NSDictionary<NSString *,Class> *)GW_ModelDelegateReplacePropertyMapper{
    return @{@"item":[itemModel class]};
}
@end
@implementation orgaModel
+ (NSDictionary<NSString *,Class> *)GW_ModelDelegateReplacePropertyMapper{
    return @{@"item":[itemModel class]};
}
@end
@implementation formattedModel

@end
@implementation telephoneModel
+ (NSDictionary<NSString *,Class> *)GW_ModelDelegateReplacePropertyMapper{
    return @{@"item":[itemModel class]};
}
@end
@implementation titleModel

@end
@implementation urlModel

@end

