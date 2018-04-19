//
//  Model2.h
//  gw_test
//
//  Created by gw on 2018/3/29.
//  Copyright © 2018年 gw. All rights reserved.
//

#import "BaseModel.h"
#import "Model3.h"
@interface Model2 : NSObject

@property (copy, nonatomic) NSString *model2Str;

@property (assign, nonatomic) int m2_Int;

@property (strong, nonatomic) Model3 *model3;
@end
