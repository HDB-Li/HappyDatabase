//
//  HDBCondition.m
//  HappyDatabase
//
//  Created by Li on 2017/5/24.
//  Copyright © 2017年 Li. All rights reserved.
//

#import "HDBCondition.h"
#import "HDBConditionGroup.h"
#import "NSString+HappyDatabase.h"
#import "HDBConfig.h"

@implementation HDBCondition

/**
 * 类初始化方法
 */
+ (instancetype)conditionType:(HDBConditionType)conditionType propertyName:(NSString *)propertyName value1:(id)value1 value2:(id)value2 {
    return [[self alloc] initWithConditionType:conditionType propertyName:propertyName value1:value1 value2:value2];
}

/**
 * 初始化方法
 */
- (instancetype)initWithConditionType:(HDBConditionType)conditionType propertyName:(NSString *)propertyName value1:(id)value1 value2:(id)value2 {
    
    if (!conditionType || propertyName.HDB_isExist == NO || !value1) {
        HDBLog(@"init condition failed, because conditionType/propertyName/value1 is empty,type = %@,name = %@,value = %@",@(conditionType),propertyName,value1);
        return nil;
    }
    
    if (self = [super init]) {
        _conditionType = conditionType;
        _propertyName = propertyName;
        _value1 = value1;
        _value2 = value2;
    }
    
    switch (conditionType) {
        case HDBConditionTypeEqual:
        case HDBConditionTypeNotEqual:
        case HDBConditionTypeBigger:
        case HDBConditionTypeBiggerOrEqual:
        case HDBConditionTypeSmaller:
        case HDBConditionTypeSmallerOrEqual:{
            if (!value1) {
                HDBLog(@"init condition failed, because value1 is nil");
                return nil;
            }
            if ([value1 isKindOfClass:[NSString class]] == NO && [value1 isKindOfClass:[NSNumber class]] == NO) {
                HDBLog(@"init condition failed, because value1 is not a NSString or a NSNumber");
                return nil;
            }
            break;
        }
        case HDBConditionTypeInside:
        case HDBConditionTypeOutside:{
            if (!value1 || !value2) {
                HDBLog(@"init condition failed, because value1/value2 is nil");
                return nil;
            }
            if ([value1 isKindOfClass:[NSString class]] == NO && [value1 isKindOfClass:[NSNumber class]] == NO) {
                HDBLog(@"init condition failed, because value1 is not a NSString or a NSNumber");
                return nil;
            }
            if ([value2 isKindOfClass:[NSString class]] == NO && [value1 isKindOfClass:[NSNumber class]] == NO) {
                HDBLog(@"init condition failed, because value2 is not a NSString or a NSNumber");
                return nil;
            }
            break;
        }
        case HDBConditionTypeIn:
        case HDBConditionTypeNotIn:{
            if (!value1) {
                HDBLog(@"init condition failed, because value1 is nil");
                return nil;
            }
            if ([value1 isKindOfClass:[NSString class]] == NO && [value1 isKindOfClass:[NSNumber class]] == NO && [value1 isKindOfClass:[NSArray class]] == NO) {
                HDBLog(@"init condition failed, because value1 is not a NSString , NSNumber or NSArray");
                return nil;
            }
            if (value2 && [value2 isKindOfClass:[NSString class]] == NO && [value2 isKindOfClass:[NSNumber class]] == NO && [value2 isKindOfClass:[NSArray class]] == NO) {
                HDBLog(@"init condition failed, because value2 is not a NSString , NSNumber or NSArray");
                return nil;
            }
            break;
        }
        default:{
            HDBLog(@"init condition failed, because condition type is unknown");
            return nil;
            break;
        }
    }

    return self;
}

#pragma mark - HDBConditionInput

/**
 * 增加"并"关系
 */
- (HDBConditionGroup *)addAndCondition:(HDBCondition *)condition {
    HDBConditionGroup *group = [[HDBConditionGroup alloc] initWithCondition:self];
    [group addAndCondition:condition];
    return group;
}

/**
 * 增加"或"关系
 */
- (HDBConditionGroup *)addOrCondition:(HDBCondition *)condition {
    HDBConditionGroup *group = [[HDBConditionGroup alloc] initWithCondition:self];
    [group addOrCondition:condition];
    return group;
}

/**
 * 判断这个关系是否有效
 */
- (BOOL)isEmpty {
    return !_conditionType;
}

/**
 * HDBCondtion转SQLite语句
 */
- (NSString *)SQLiteString {
    switch (_conditionType) {
        case HDBConditionTypeEqual:{
            return [NSString stringWithFormat:@" %@ == %@ ",_propertyName,_value1];
            break;
        }
        case HDBConditionTypeNotEqual:{
            return [NSString stringWithFormat:@" %@ != %@ ",_propertyName,_value1];
            break;
        }
        case HDBConditionTypeBigger:{
            return [NSString stringWithFormat:@" %@ > %@ ",_propertyName,_value1];
            break;
        }
        case HDBConditionTypeBiggerOrEqual:{
            return [NSString stringWithFormat:@" %@ >= %@ ",_propertyName,_value1];
            break;
        }
        case HDBConditionTypeSmaller:{
            return [NSString stringWithFormat:@" %@ < %@ ",_propertyName,_value1];
            break;
        }
        case HDBConditionTypeSmallerOrEqual:{
            return [NSString stringWithFormat:@" %@ <= %@ ",_propertyName,_value1];
            break;
        }
        case HDBConditionTypeInside:{
            return [NSString stringWithFormat:@" %@ BETWEEN %@ AND %@",_propertyName,_value1,_value2];
            break;
        }
        case HDBConditionTypeOutside:{
            return [NSString stringWithFormat:@" %@ NOT BETWEEN %@ AND %@",_propertyName,_value1,_value2];
            break;
        }
        case HDBConditionTypeIn:{
            NSMutableArray *array = [[NSMutableArray alloc] init];
            if ([_value1 isKindOfClass:[NSString class]]) {
                [array addObject:_value1];
            } else if ([_value1 isKindOfClass:[NSArray class]]) {
                [array addObjectsFromArray:_value1];
            }
            if ([_value2 isKindOfClass:[NSString class]]) {
                [array addObject:_value2];
            } else if ([_value2 isKindOfClass:[NSArray class]]) {
                [array addObjectsFromArray:_value2];
            }
            NSMutableString *SQLiteString = [[NSMutableString alloc] initWithFormat:@" %@ IN (",_propertyName];
            for (NSString *value in array) {
                [SQLiteString appendFormat:@" '%@' ,",value];
            }
            [SQLiteString deleteCharactersInRange:NSMakeRange(SQLiteString.length - 1, 1)];
            [SQLiteString appendString:@")"];
            return SQLiteString;
            break;
        }
        case HDBConditionTypeNotIn:{
            NSMutableArray *array = [[NSMutableArray alloc] init];
            if ([_value1 isKindOfClass:[NSString class]]) {
                [array addObject:_value1];
            } else if ([_value1 isKindOfClass:[NSArray class]]) {
                [array addObjectsFromArray:_value1];
            }
            if ([_value2 isKindOfClass:[NSString class]]) {
                [array addObject:_value2];
            } else if ([_value2 isKindOfClass:[NSArray class]]) {
                [array addObjectsFromArray:_value2];
            }
            NSMutableString *SQLiteString = [[NSMutableString alloc] initWithFormat:@" %@ NOT IN (",_propertyName];
            for (NSString *value in array) {
                [SQLiteString appendFormat:@" '%@' ,",value];
            }
            [SQLiteString deleteCharactersInRange:NSMakeRange(SQLiteString.length - 1, 1)];
            [SQLiteString appendString:@")"];
            return SQLiteString;
            break;
        }
        default:
            break;
    }
    return nil;
}

@end
