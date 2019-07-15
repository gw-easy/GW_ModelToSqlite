//
//  Test_model3.m
//  GW_ModelToSqlite
//
//  Created by zdwx on 2019/7/15.
//  Copyright © 2019 gw. All rights reserved.
//

#import "Test_model3.h"

@implementation Test_model3
+(NSDictionary<NSString *,Class> *)GW_ModelDelegateReplacePropertyMapper{
    return @{@"Children":[Test_model3 class]};
}

+ (void)GW_JsonToModelFinish:(NSObject *)Obj{
    if ([Obj isKindOfClass:[Test_model3 class]]) {
        Test_model3 *tModel =(Test_model3 *)Obj;
        tModel.hasChild = tModel.Children.count > 0;
    }
}
@end
