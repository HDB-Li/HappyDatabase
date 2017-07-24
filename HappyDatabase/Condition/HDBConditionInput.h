//
//  HDBConditionInput.h
//  HappyDatabase
//
//  Created by Li on 2017/5/24.
//  Copyright © 2017年 Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HDBConditionGroup;

@protocol HDBConditionInput <NSObject>

/**
 * 添加一个AND/OR的条件约束
 */
- (HDBConditionGroup *)addAndCondition:(id<HDBConditionInput>)condition;
- (HDBConditionGroup *)addOrCondition:(id<HDBConditionInput>)condition;

/**
 * 将条件转化成SQLite语句
 */
- (NSString *)SQLiteString;

/**
 * 数据完整型判断
 */
- (BOOL)isEmpty;

@end
