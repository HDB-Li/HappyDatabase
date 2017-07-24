//
//  HDBConditionGroup.m
//  HappyDatabase
//
//  Created by Li on 2017/5/24.
//  Copyright © 2017年 Li. All rights reserved.
//

#import "HDBConditionGroup.h"
#import "HDBConditionItem.h"
#import "HDBManager.h"

@interface HDBConditionGroup ()

@property (nonatomic, strong) NSMutableArray *conditionItems;

@property (nonatomic, strong) id firstCondition;

@property (nonatomic, copy) NSString *SQLiteString;

@end

@implementation HDBConditionGroup


/**
 * 初始化方法
 */
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self __initial];
    }
    return self;
}

- (instancetype)initWithCondition:(id)condition {
    if (self = [super init]) {
        [self __initial];
        _firstCondition = condition;
    }
    return self;
}

#pragma mark - Primary Method

/**
 内部初始化方法
 */
- (void)__initial {
    _conditionItems = [[NSMutableArray alloc] init];
}


/**
 * 添加关系
 */
- (HDBConditionGroup *)addCondition:(id)condition isAnd:(BOOL)isAnd {
    if (_firstCondition == nil) {
        _firstCondition = condition;
        return self;
    }
    if ([condition isEmpty]) {
        HDBLog(@"add Condition failed,because condition is empty");
        return self;
    }
    HDBConditionItem *item = [HDBConditionItem itemWithFirstCondition:_firstCondition secondCondition:condition isAnd:isAnd];
    [_conditionItems addObject:item];
    _firstCondition = self;
    _SQLiteString = nil;
    return self;
}

#pragma mark - HDBConditionInput

/**
 * 增加"并"关系
 */
- (HDBConditionGroup *)addAndCondition:(id)condition {
    return [self addCondition:condition isAnd:YES];
}

/**
 * 增加"或"关系
 */
- (HDBConditionGroup *)addOrCondition:(id)condition {
    return [self addCondition:condition isAnd:NO];
}

/**
 * 判断这个关系是否有效
 */
- (BOOL)isEmpty {
    return !_firstCondition;
}

/**
 * HDBCondtionGroup转SQLite语句
 */
- (NSString *)SQLiteString {
    if (!_SQLiteString) {
        for (HDBConditionItem *item in _conditionItems) {
            NSString *ship = item.isAnd ? @"AND" : @"OR";
            NSString *firstSQLiteString = item.firstCondition == self ? _SQLiteString :[item.firstCondition SQLiteString];
            NSString *secondSQLiteString = item.secondCondition == self ? _SQLiteString : [item.secondCondition SQLiteString];
            _SQLiteString = [NSString stringWithFormat:@"(%@ %@ %@)",firstSQLiteString,ship,secondSQLiteString];
        }
    }
    return _SQLiteString;
}

@end
