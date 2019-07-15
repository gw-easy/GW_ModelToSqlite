//
//  Test_Model2.h
//  GW_ModelKit
//
//  Created by gw on 2018/4/8.
//  Copyright © 2018年 gw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+GW_Model.h"
#import "Model1.h"
@interface itemModel:NSObject
@property (copy, nonatomic) NSString *country;
@property (copy, nonatomic) NSString *locality;
@property (copy, nonatomic) NSString *postal_code;
@property (copy, nonatomic) NSString *street;
@property (copy, nonatomic) NSString *address;
@property (copy, nonatomic) NSString *family_name;
@property (copy, nonatomic) NSString *given_name;
@property (copy, nonatomic) NSString *unit;
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *number;
@property (strong, nonatomic) Model1 *setModel;
@property (strong, nonatomic) NSArray<NSString*> *type;


@end

@interface addressModel:NSObject
@property (strong, nonatomic) itemModel *item;
@property (copy, nonatomic) NSString *position;

@end

@interface emailModel:NSObject
@property (copy, nonatomic) NSString *item;
@property (copy, nonatomic) NSString *position;

@end

@interface formattedModel:NSObject
@property (copy, nonatomic) NSString *item;
@property (copy, nonatomic) NSString *position;
@end

@interface labelModel:NSObject
@property (strong, nonatomic) itemModel *item;
@property (copy, nonatomic) NSString *position;
@end

@interface nameModel:NSObject
@property (strong, nonatomic) itemModel *item;
@property (copy, nonatomic) NSString *position;
@end

@interface orgaModel:NSObject
@property (strong, nonatomic) itemModel *item;
@property (copy, nonatomic) NSString *position;
@end

@interface telephoneModel:NSObject
@property (strong, nonatomic) itemModel *item;
@property (copy, nonatomic) NSString *position;
@end

@interface titleModel:NSObject
@property (copy, nonatomic) NSString *item;
@property (copy, nonatomic) NSString *position;
@end

@interface urlModel:NSObject
@property (copy, nonatomic) NSString *item;
@property (copy, nonatomic) NSString *position;
@end

@interface Test_Model2 : NSObject
@property (copy, nonatomic) NSString *rotation_angle;
@property (strong, nonatomic) NSArray<addressModel*> *address;
@property (strong, nonatomic) NSArray<emailModel*> *email;
@property (strong, nonatomic) NSArray<formattedModel*> *formatted_name;
@property (strong, nonatomic) NSArray<labelModel*> *label;
@property (strong, nonatomic) NSArray<nameModel*> *name;
@property (strong, nonatomic) NSArray<orgaModel*> *organization;
@property (strong, nonatomic) NSArray<telephoneModel*> *telephone;
@property (strong, nonatomic) NSArray<titleModel*> *title;
@property (strong, nonatomic) NSArray<urlModel*> *url;
@property (strong, nonatomic) Model1 *setModel;
@end
