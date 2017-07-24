//
//  HDBConditionItem.h
//  HappyDatabase
//
//  Created by Li on 2017/5/24.
//  Copyright © 2017年 Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HDBConditionInput.h"

@interface HDBConditionItem : NSObject

/**
 * 约束1
 */
@property (nonatomic, strong ,readonly) id firstCondition;

/**
 * 约束2
 */
@property (nonatomic, strong ,readonly) id secondCondition;

/**
 * 约束1与约束2之间的关系,YES:AND NO:OR
 */
@property (nonatomic, assign ,readonly) BOOL isAnd;

/**
 * 指定的初始化方法
 */
+ (instancetype)itemWithFirstCondition:(id<HDBConditionInput>)firstCondition secondCondition:(id<HDBConditionInput>)secondCondition isAnd:(BOOL)isAnd;

@end
