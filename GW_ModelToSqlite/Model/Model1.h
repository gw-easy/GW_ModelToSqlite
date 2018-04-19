//
//  Model1.h
//  gw_test
//
//  Created by gw on 2018/3/29.
//  Copyright © 2018年 gw. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "BaseModel.h"
#import "Model2.h"
@interface Model1 : BaseModel
@property (copy, nonatomic) NSString *model1Str;

@property (assign, nonatomic) int model1_int;

@property (strong, nonatomic) NSNumber *num;

@property (strong, nonatomic) NSMutableArray *arr;

@property (strong, nonatomic) Model2 *model2;

//@property (copy, nonatomic) NSString *strstr111;
//
//@property (assign, nonatomic) int numCode;
//
//@property (assign, nonatomic) NSInteger gerCode;

@property (assign, nonatomic) NSInteger dddr;

@property (copy, nonatomic) void (^addBlock)(void);


@end




