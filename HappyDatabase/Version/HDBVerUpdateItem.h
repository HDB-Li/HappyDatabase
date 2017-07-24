//
//  HDBVerUpdateItem.h
//  HappyDatabase
//
//  Created by Li on 2017/5/23.
//  Copyright © 2017年 Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HDBVerUpdateItem : NSObject

/**
 * 模型名称
 */
@property (nonatomic, copy , readonly) NSString *modelName;

/**
 * 对应的版本
 */
@property (nonatomic, copy , readonly) NSString *version;

/**
 * 新旧属性名字典,旧属性名为key,新属性名为value
 */
@property (nonatomic, strong , readonly) NSDictionary *parameters;

/**
 * 指定的初始化方法

 @param modelName 模型名称
 @param version 对应的版本
 @param parameters 新旧属性名字典,旧属性名为key,新属性名为value
 */
- (instancetype)initWithModelName:(NSString *)modelName version:(NSString *)version parameters:(NSDictionary *)parameters;

@end
