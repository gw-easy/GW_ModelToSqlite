//
//  ViewController.m
//  GW_ModelToSqlite
//
//  Created by gw on 2018/4/9.
//  Copyright © 2018年 gw. All rights reserved.
//

#import "ViewController.h"
#import "GW_ModelToSqlite.h"
#import "TestModel.h"
#import "Test_Model2.h"
#import "NSObject+GW_Model.h"
#define mainP [NSString stringWithFormat:@"%@/Library/Caches/gw",NSHomeDirectory()]
#define siPath @"gw/hehe/"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    /// 从文件ModelObject读取json对象
//    NSString * jsonString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ModelObject" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil];
//    Model1 *list1 = [Model1 GW_JsonToModel:jsonString keyPath:@"data/setModel"];
//    list1.gerCode = 5;
//    [GW_ModelToSqlite insertModel:list1];
    
//    NSArray *arr = [GW_ModelToSqlite query:[Model1 class]];
//
//    for (int i = 0; i<arr.count; i++) {
//        Model1 *ms = arr[i];
//        ms.numCode = i;
//        ms.strstr111 = [NSString stringWithFormat:@"%d--ms",i];
////        ms.gerCode = i;
//        [GW_ModelToSqlite update:ms where:[NSString stringWithFormat:@"model1_int = %d",i]];
////        [GW_ModelToSqlite update:ms where:[NSString stringWithFormat:@"model1_int = %d",i]];
//    }

    
    
    [GW_ModelToSqlite delete_class:[Model1 class] where:@"model1_int = 1"];
    
    NSArray *arr2 = [GW_ModelToSqlite query:[Model1 class]];
    for (Model1 *tb in arr2) {
        NSLog(@"tb==%@",[tb GW_ModelToDictionary:tb]);
    }
//    [GW_ModelToSqlite removeAllTable];
//    [self test1];

    
}

- (void)test1{
    /// 从文件ModelObject读取json对象
    NSString * jsonString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ModelObject" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil];
    
    TestModel *testmodel = [TestModel GW_JsonToModel:jsonString keyPath:nil changeDic:@{
                                                                                        @"partnerteamlist":[Partnerteamlist_test class],
                                                                                        @"liketeamlist":[Liketeam_testContent class],
                                                                                        @"feedbacklist":[feedback_testContent class]
                                                                                        }];
    
    
    BOOL result = [GW_ModelToSqlite insertModel:testmodel];
    
    if (result) {
        NSArray *testArr = [GW_ModelToSqlite query:[testmodel class]];
        for (TestModel *tes in testArr) {
            NSLog(@"tes --- %@",tes);
            for (feedback_testContent *mm in testmodel.data.feedbacks.feedbacklist) {
                
                
                NSLog(@"%@----",mm.setModel.model1Str);
            }
            
            
            for (Partnerteamlist_test *par in testmodel.data.partnerteamlist) {
                NSLog(@"%@----%@",par,par.setModel);
            }
            
            
            for (Liketeam_testContent *like in testmodel.data.liketeamlist) {
                NSLog(@"%@-----%@",like,like.seModel);
            }
            NSLog(@"sssss===%@",testmodel.setModel);
            NSLog(@"testModel === %@",[testmodel GW_ModelToDictionary:testmodel]);
            NSLog(@"testModel===%@-------%@",testmodel.data.partnerteamlist,testmodel.data.liketeamlist);
        }
    }

    
    Model1 *list1 = [Model1 GW_JsonToModel:jsonString keyPath:@"data/setModel"];
    
    list1.arr = [NSMutableArray arrayWithArray:@[@"111",@"222",@"333"]];
//    
    Model1 *list3 = [list1 copy];
    list3.baseMM_float = 666;
    list3.model1_int = 1;
    Model1 *list4 = [list3 copy];
    list4.model1_int = 2;
    Model1 *list5 = [list4 copy];
    list5.model1_int = 3;
    list5.baseMM_float = 666;
    list5.model1Str = @"gw";
    Model1 *list6 = [list5 copy];
    list6.model1_int = 4;
    NSArray *listArr = @[list1,list3,list4,list5,list6];
    [GW_ModelToSqlite insertArrayModel:listArr];

    //指定搜索对象
    [self getWhereArr];

    //根据某个属性降序
    [self getDescArr];

    //根据某个属性升序
    [self getAscArr];

//    限制查询数量
    [self getLimitArr];

//    有查询条件和数量限制
    [self getWhereAndLimitArr];

//    有排序和数量限制
    [self getOrderAndLimitArr];

//    有查询条件/有排序/数量限制
    [self getwhereorderlimitArr];

//    通过sqlite自有函数查询
    [self getFuncStr1Arr];

//    通过sqlite自有函数查询+条件
    [self getfuncAndConditionNB];

//    更新model+位置
    [self getupdateAndWhere];

//    指定某个值更改
    [self getupdatevaluewhereArr];
}

- (void)getupdatevaluewhereArr{
    [GW_ModelToSqlite update:[Model1 class] value:@"model1Str = 'yjy'" where:@"model1_int = 3"];
    NSArray *updatevaluewhereArr = [GW_ModelToSqlite query:[Model1 class] where:[NSString stringWithFormat:@"model1_int = %d",3]];
    for (Model1 *ls6 in updatevaluewhereArr) {
        NSLog(@"%@",ls6.model1Str);
    }
}

- (void)getupdateAndWhere{
    NSArray *ls6Arr = [GW_ModelToSqlite query:[Model1 class] where:[NSString stringWithFormat:@"model1_int = %d",4]];
    Model1 *list7 = ls6Arr.firstObject;
    list7.model1Str = @"yj";
    [GW_ModelToSqlite update:list7 where:@"model1_int = 4"];
    ls6Arr = [GW_ModelToSqlite query:[Model1 class] where:[NSString stringWithFormat:@"model1_int = %d",4]];
    for (Model1 *ls6 in ls6Arr) {
        NSLog(@"%@",ls6.model1Str);
    }
}

- (void)getwhereorderlimitArr{
    NSArray *whereorderlimitArr = [GW_ModelToSqlite query:[Model1 class] where:[NSString stringWithFormat:@"baseMM_float = '%d'",666] order:@"by model1_int asc" limit:@"2"];
    NSLog(@"whereorderlimitArr = %@",whereorderlimitArr);
}

- (void)getfuncAndConditionNB{
    NSNumber *funcAndConditionNB = [GW_ModelToSqlite query:[Model1 class] func:@"count(*)" condition:@"where baseMM_float = '666'"];
    NSLog(@"funcAndConditionArr = %ld",(long)funcAndConditionNB.integerValue);
}

- (void)getFuncStr1Arr{
    NSArray *funcStr1Arr = [GW_ModelToSqlite query:[Model1 class] func:@"model1Str,length(model1Str)"];
    NSLog(@"funcStr1Arr = %@",funcStr1Arr);
    
    NSNumber * maxAge = [GW_ModelToSqlite query:[Model1 class] func:@"max(model1_int)"];
    NSLog(@"maxAge = %@",maxAge);
}

- (void)getWhereAndOrderArr{
    NSArray *whereAndOrderArr = [GW_ModelToSqlite query:[Model1 class] where:[NSString stringWithFormat:@"baseMM_float = '%d'",666] order:@"by model1_int asc"];
    for (Model1 *wo in whereAndOrderArr) {
        NSLog(@"wo.model1_int = %d",wo.model1_int);
    }
}

- (void)getOrderAndLimitArr{
    NSArray *orderAndLimitArr=[GW_ModelToSqlite query:[Model1 class] order:@"by model1_int desc" limit:@"2"];
    NSLog(@"orderAndLimitArr = %lu",(unsigned long)orderAndLimitArr.count);
    for (Model1 *ol in orderAndLimitArr) {
        NSLog(@"ol.model1_int = %d",ol.model1_int);
    }
}

- (void)getWhereAndLimitArr{
    NSArray *whereAndLimitArr =[GW_ModelToSqlite query:[Model1 class] where:[NSString stringWithFormat:@"baseMM_float = '%d'",666] limit:@"1"];
    NSLog(@"whereAndLimitArr = %lu",(unsigned long)whereAndLimitArr.count);
    for (Model1 *wl in whereAndLimitArr) {
        NSLog(@"wl.model1_int = %d----wl.baseMM_float = %f",wl.model1_int,wl.baseMM_float);
    }
}

- (void)getLimitArr{
    NSArray *limitArr = [GW_ModelToSqlite query:[Model1 class] limit:@"2"];
    NSLog(@"limitArr = %lu",(unsigned long)limitArr.count);
}

- (void)getWhereArr{
    NSArray *qArr = [GW_ModelToSqlite query:[Model1 class] where:[NSString stringWithFormat:@"baseMM_float = '%d'",666]];
    for (Model1 *li in qArr) {
        NSLog(@"%@----",[li GW_ModelToDictionary:li]);
    }
}

- (void)getDescArr{
    NSArray *descArr = [GW_ModelToSqlite query:[Model1 class] order:@"by model1_int desc"];
    for (Model1 *desc in descArr) {
        NSLog(@"model1_int = %d",desc.model1_int);
    }
}

- (void)getAscArr{
    NSArray *ascArr = [GW_ModelToSqlite query:[Model1 class] order:@"by model1_int asc"];
    for (Model1 *asc in ascArr) {
        NSLog(@"model1_int = %d",asc.model1_int);
    }
}

- (void)test2{
    //    NSString * jsonString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"test_json" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil];
    NSData *data= [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"test_json" ofType:@"json"]];
    Test_Model2 *model2 = [Test_Model2 GW_JsonToModel:data keyPath:nil changeDic:@{
                                                                                   @"organization":[orgaModel class]
                                                                                   }];
    
    NSLog(@"model2 = %@",[model2 GW_ModelToDictionary:model2]);
    
    for (orgaModel *orga in model2.organization) {
        NSLog(@"%@-----%@",orga.item.unit,orga.item.name);
    }
    
    for (addressModel *addr in model2.address) {
        NSLog(@"%@-----%@",addr.item.setModel,addr.item.setModel.model1Str);
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
