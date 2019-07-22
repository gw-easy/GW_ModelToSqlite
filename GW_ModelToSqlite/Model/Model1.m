//
//  Model1.m
//  gw_test
//
//  Created by gw on 2018/3/29.
//  Copyright © 2018年 gw. All rights reserved.
//

#import "Model1.h"
#import "NSObject+GW_Model.h"
@interface Model1()

@end
@implementation Model1
+(NSDictionary<NSString *,NSString *> *)GW_ModelDelegateReplacePropertyValue{
    return @{@"model1Str":@"model1Str2"};
}
@end


