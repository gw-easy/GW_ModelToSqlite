//
//  TestModel.h
//  GW_ModelKit
//
//  Created by gw on 2018/4/4.
//  Copyright © 2018年 gw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model1.h"

@interface feedback_testContent :NSObject
@property (nonatomic , copy) NSString *comment;
@property (nonatomic , assign) NSInteger Fee;
@property (strong, nonatomic) NSDate *createtime;
@property (assign, nonatomic) int score;
@property (nonatomic , copy) NSString *username;
@property (strong, nonatomic) Model1 *setModel;
@end

@interface Head_test :NSObject
@property (nonatomic , copy) NSString *totalcount;
@property (nonatomic , copy) NSString *totalscore;
@property (strong, nonatomic) NSArray<feedback_testContent*> *feedbacklist;

@end

@interface Partnerteamlist_test :NSObject
@property (nonatomic , assign) NSInteger pteamId;
@property (assign, nonatomic) NSInteger pteamprice;
@property (nonatomic , copy) NSString * ptitle;
@property (strong, nonatomic) Model1 *setModel;
@end

@interface Liketeam_testContent:NSObject
@property (copy, nonatomic) NSString *limage;
@property (assign, nonatomic) float lmarketprice;
@property (assign, nonatomic) NSInteger lteamId;
@property (assign, nonatomic) NSInteger lteamprice;
@property (copy, nonatomic) NSString *ltitle;
@property (strong, nonatomic) Model1 *seModel;
@end


@interface response_Test:NSObject
@property (strong, nonatomic) Head_test *feedbacks;
@property (strong, nonatomic) NSArray<Partnerteamlist_test*> *partnerteamlist;
@property (strong, nonatomic) NSArray<Liketeam_testContent*> *liketeamlist;
@property (strong, nonatomic) Model1 *setModel;
@end

@interface TestModel : NSObject
@property (strong, nonatomic) NSString *err;
@property (strong, nonatomic) response_Test *data;
@property (assign, nonatomic) int state;
@property (assign, nonatomic) int state2;
@property (strong, nonatomic) Model1 *setModel;
@end
