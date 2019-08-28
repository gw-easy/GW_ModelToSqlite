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
#import "Test_model3.h"
#import "NSObject+GW_Model.h"
#import "SsqModel.h"
@interface ViewController ()

@end

@implementation ViewController

- (IBAction)test_1:(id)sender {
    /// 从文件ModelObject读取json对象
    NSString * jsonString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ModelObject" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil];
    
    TestModel *testmodel = [TestModel GW_JsonToModel:jsonString keyPath:nil changeDic:@{
                                                                                        @"partnerteamlist":[Partnerteamlist_test class],
                                                                                        @"liketeamlist":[Liketeam_testContent class],
                                                                                        @"feedbacklist":[feedback_testContent class]
                                                                                        }];
    
    
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
    NSLog(@"testmodel.state =%d , testmodel.state2 =%d",testmodel.state,testmodel.state2);
    NSLog(@"testModel === %@",[testmodel GW_ModelToDictionary:testmodel]);
    NSLog(@"testModel===%@-------%@",testmodel.data.partnerteamlist,testmodel.data.liketeamlist);
    
    NSData *testData = [NSKeyedArchiver archivedDataWithRootObject:testmodel];
    TestModel *testM2 = [NSKeyedUnarchiver unarchiveObjectWithData:testData];
    NSLog(@"testM2===%@-------%@",testM2.data.partnerteamlist,testM2.data.liketeamlist);
    
    
    NSArray *arr = [feedback_testContent GW_JsonToModel:jsonString keyPath:@"data/feedbacks/feedbacklist"];
    
    for (feedback_testContent *list in arr) {
        
        NSLog(@"list = %@\n",[list GW_ModelToDictionary:list]);
    }
    
    Model1 *list1 = [Model1 GW_JsonToModel:jsonString keyPath:@"data/setModel"];
    /************** 归档对象 **************/
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:list1];
    
    /************** 解归档对象 **************/
    Model1 *list2 = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSLog(@"list2 = %@\n",[list2 GW_ModelToDictionary:list2]);
    
    Model1 *list3 = [list2 copy];
    list3.baseMM_float = 666;
    NSLog(@"list3==%@----list2==%@",list3,list2);
    NSLog(@"list3.Index==%ld-----list2.Index==%ld",(long)list3.baseMM_float,(long)list2.baseMM_float);
}

- (IBAction)test_2:(id)sender {
    /// 从文件test_json读取json对象
    NSString * jsonString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"test_json" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil];
    
    Test_Model2 *model2 = [Test_Model2 GW_JsonToModel:jsonString];
    
    for (addressModel *addr in model2.address) {
        NSLog(@"addressModel = %@",addr);
    }
    
    for (emailModel *addr in model2.email) {
        NSLog(@"emailModel = %@",addr);
    }
    
    NSLog(@"setModel = %@,setModel.model2 = %@",model2.setModel,model2.setModel.model2);
}

- (IBAction)test_3:(id)sender {
    NSString * jsonString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"test_json2" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil];
    
    NSMutableArray *model3Arr = [Test_model3 GW_JsonToModel:jsonString keyPath:@"Data"];
    
    [self showID:model3Arr];
}

- (void)showID:(NSArray *)childArr{
    for (Test_model3 *child in childArr) {
        NSLog(@"childID = %@ ---- hasChild = %@",child.Id,@(child.hasChild));
        if (child.Children.count > 0) {
            [self showID:child.Children];
        }
    }
}

- (IBAction)test_4:(id)sender {
    NSString * jsonString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ModelObject" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil];
    
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

- (void)viewDidLoad {
    [super viewDidLoad];

//    清理数据
    [GW_ModelToSqlite removeAllTable];
    
    [self test5];
}

- (void)test5{
    NSArray *subArr =nil;
    NSString *jsonStr = [subArr GW_ModelToJson:subArr];
    NSLog(@"%---@",jsonStr);
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

- (IBAction)ssqAction:(id)sender {
    NSData *data= [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ssq" ofType:@"json"]];
    NSArray *ssqMArr = [SsqModel GW_JsonToModel:data];
    
//    NSLog(@"model2 = %@",[ssqMArr GW_ModelToJson:nil]);
    
    for (int i = 0; i<ssqMArr.count; i++) {
        for (int y = i+1; y<ssqMArr.count; y++) {
            [self dict:ssqMArr[i] isEqualTo:ssqMArr[y] addBlue:NO];
        }
    }
    
}

- (BOOL)dict:(SsqModel *)dict1 isEqualTo:(SsqModel *)dict2 addBlue:(BOOL)blue{
    if ([dict1.red1 isEqualToString:dict2.red1]
        && [dict1.red2 isEqualToString:dict2.red2]
        && [dict1.red3 isEqualToString:dict2.red3]
        && [dict1.red4 isEqualToString:dict2.red4]
        && [dict1.red5 isEqualToString:dict2.red5]
        && [dict1.red6 isEqualToString:dict2.red6]
        ) {
        if (blue && [dict1.blue isEqualToString:dict2.blue]) {
            NSLog(@"相同model-date = %@ -- %@",dict1.date,dict2.date);
            NSLog(@"red1 = %@ red2 = %@ red3 = %@ red4 = %@ red5 = %@ red6 =  %@",dict1.red1,dict1.red2,dict1.red3,dict1.red4,dict1.red5,dict1.red6);
            NSLog(@"blue = %@",dict1.blue);
            return YES;
        }
        NSLog(@"相同model-date = %@ -- %@",dict1.date,dict2.date);
        NSLog(@"red1 = %@ red2 = %@ red3 = %@ red4 = %@ red5 = %@ red6 =  %@",dict1.red1,dict1.red2,dict1.red3,dict1.red4,dict1.red5,dict1.red6);
        return YES;
    }
    return NO;
}
    


    
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"didReceiveMemoryWarning");
}


@end
