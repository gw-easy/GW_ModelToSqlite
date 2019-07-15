//
//  Test_model3.h
//  GW_ModelToSqlite
//
//  Created by zdwx on 2019/7/15.
//  Copyright © 2019 gw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+GW_Model.h"
NS_ASSUME_NONNULL_BEGIN

@interface Test_model3 : NSObject
@property (copy, nonatomic) NSNumber *Process;
@property (copy, nonatomic) NSString *LectureNotesInfo;
@property (nonatomic,copy) NSString *Id;
@property (nonatomic,strong) NSMutableArray<Test_model3 *> *Children;
@property (nonatomic,copy) NSString *Title;
@property (nonatomic,copy) NSString *ParentID;
@property (nonatomic,copy) NSString *ClassHoursInfo;
@property (nonatomic,copy) NSString *pBuyInfo;
@property (nonatomic,copy) NSString *Status;
@property (nonatomic,copy) NSString *MP4Url;
//是否有子类
@property (assign ,nonatomic) BOOL hasChild;
@end

NS_ASSUME_NONNULL_END
