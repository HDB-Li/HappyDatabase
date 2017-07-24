//
//  HDBCondition.h
//  HappyDatabase
//
//  Created by Li on 2017/5/24.
//  Copyright © 2017年 Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HDBConditionInput.h"

/**
 条件约束类型

 - HDBConditionTypeEqual: 相等
 - HDBConditionTypeNotEqual: 不等于
 - HDBConditionTypeBigger: 大于
 - HDBConditionTypeBiggerOrEqual: 大于等于
 - HDBConditionTypeSmaller: 小于
 - HDBConditionTypeSmallerOrEqual: 小于等于
 - HDBConditionTypeInside: 范围内
 - HDBConditionTypeOutside: 范围外
 - HDBConditionTypeIn: 包含在数组内
 - HDBConditionTypeNotIn: 不包含在数组内
 */
typedef NS_ENUM(NSUInteger, HDBConditionType) {
    HDBConditionTypeEqual           = 1,
    HDBConditionTypeNotEqual,
    HDBConditionTypeBigger,
    HDBConditionTypeBiggerOrEqual,
    HDBConditionTypeSmaller,
    HDBConditionTypeSmallerOrEqual,
    HDBConditionTypeInside,     // In the range
    HDBConditionTypeOutside,    // Out the range
    HDBConditionTypeIn,         // In the array
    HDBConditionTypeNotIn,      // Out the array
};

@interface HDBCondition : NSObject <HDBConditionInput>

/**
 * 约束类型,枚举值,表示propertyName与values之间约束条件
 */
@property (nonatomic, assign ,readonly) HDBConditionType conditionType;

/**
 * 约束的属性名
 */
@property (nonatomic, copy ,readonly) NSString *propertyName;

/**
 * 操作值1
 * value1
 */
@property (nonatomic, copy ,readonly) id value1;

/**
 * 操作值2
 * value2
 */
@property (nonatomic, copy ,readonly) id value2;

/**
 * 指定的初始化方法
 * 当约束条件为HDBConditionTypeInside / HDBConditionTypeOutside / HDBConditionTypeIn / HDBConditionTypeNotIn时,需要传value2,其他情况value2可以直接传nil
 * 当约束条件为HDBConditionTypeIn / HDBConditionTypeNotIn时,value1和value2可以为NSNumber,NSString或者NSArray,其他情况时value1或value2只可以是NSNumber或者NSString.
 */
+ (instancetype)conditionType:(HDBConditionType)conditionType propertyName:(NSString *)propertyName value1:(id)value1 value2:(id)value2;

@end
