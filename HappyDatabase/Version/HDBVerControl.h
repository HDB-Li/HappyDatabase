//
//  HDBVerControl.h
//  HappyDatabase
//
//  Created by Li on 2017/5/23.
//  Copyright © 2017年 Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HDBVerControl : NSObject

/**
 * 单例
 */
+ (instancetype)sharedControl;

/**
 * 检查是否需要更新本地数据库

 @return YES:需要 NO:不需要
 */
- (BOOL)needUpdateVersion;

/**
 * 开始同步本地数据库到最新格式

 @return YES:成功 NO:失败
 */
- (BOOL)beginUpdateVersion;

/**
 * 设置数据库同步格式
 * 需要在beginUpdateVersion之前设置
 * 只适用于模型中新旧属性名的替换,不适用于增减属性名
 
 @param modelName 模型名称,eg:Person
 @param version 新属性名对应的版本,eg:1.1.0
 @param parameters 新旧属性名字典,旧属性名为key,新属性名为value
 */
- (void)configModel:(NSString *)modelName version:(NSString *)version parameters:(NSDictionary *)parameters;

/**
 * HDB版本号
 */
- (NSString *)version;

/**
 * App版本号
 */
- (NSString *)appVersion;

@end
