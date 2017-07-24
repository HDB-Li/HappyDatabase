//
//  HDBConditionGroup.h
//  HappyDatabase
//
//  Created by Li on 2017/5/24.
//  Copyright © 2017年 Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HDBConditionInput.h"

@interface HDBConditionGroup : NSObject <HDBConditionInput>

/**
 * 指定的初始化方法
 */
- (instancetype)initWithCondition:(id<HDBConditionInput>)condition;

@end
