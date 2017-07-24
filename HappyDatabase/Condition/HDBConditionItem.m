//
//  HDBConditionItem.m
//  HappyDatabase
//
//  Created by Li on 2017/5/24.
//  Copyright © 2017年 Li. All rights reserved.
//

#import "HDBConditionItem.h"

@implementation HDBConditionItem

/**
 * 类初始化方法
 */
+ (instancetype)itemWithFirstCondition:(id)firstCondition secondCondition:(id)secondCondition isAnd:(BOOL)isAnd {
    return [[self alloc] initWithFirstCondition:firstCondition secondCondition:secondCondition isAnd:isAnd];
}

/**
 * 初始化方法
 */
- (instancetype)initWithFirstCondition:(id)firstCondition secondCondition:(id)secondCondition isAnd:(BOOL)isAnd {
    if (self = [super init]) {
        _firstCondition = firstCondition;
        _secondCondition = secondCondition;
        _isAnd = isAnd;
    }
    return self;
}

@end
