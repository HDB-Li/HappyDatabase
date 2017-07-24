//
//  HDBVerUpdateItem.m
//  HappyDatabase
//
//  Created by Li on 2017/5/23.
//  Copyright © 2017年 Li. All rights reserved.
//

#import "HDBVerUpdateItem.h"

@implementation HDBVerUpdateItem

/**
 * 指定的初始化方法
 */
- (instancetype)initWithModelName:(NSString *)modelName version:(NSString *)version parameters:(NSDictionary *)parameters {
    if (self = [super init]) {
        _modelName = modelName;
        _version = version;
        _parameters = parameters;
    }
    return self;
}

@end
