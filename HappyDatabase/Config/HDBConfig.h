//
//  HDBConfig.h
//  HappyDatabase
//
//  Created by Li on 2017/5/23.
//  Copyright © 2017年 Li. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#define HDBLog(FORMAT, ...) NSLog((FORMAT), ##__VA_ARGS__);
#else
#define HDBLog(FORMAT, ...) nil
#endif

@interface HDBConfig : NSObject

/**
 * 文件存储路径
 */
@property (nonatomic, copy, readonly) NSString *path;

/**
 * 单例
 */
+ (instancetype)defaultConfig;

/**
 * 设置debugLog模式
 
 @param isDebug YES:有调试信息 NO:没有调试信息
 */
+ (void)setDebugMode:(BOOL)isDebug;

/**
 * 设置数据存储路径,默认是Documents/HappyDatabase/
 
 @param path DB path
 */
+ (void)configPath:(NSString *)path;

@end
