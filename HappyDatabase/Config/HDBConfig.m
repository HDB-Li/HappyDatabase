//
//  HDBConfig.m
//  HappyDatabase
//
//  Created by Li on 2017/5/23.
//  Copyright © 2017年 Li. All rights reserved.
//

#import "HDBConfig.h"

static HDBConfig *_instance = nil;

@interface HDBConfig ()

/**
 文件存储路径
 */
@property (nonatomic, copy) NSString *path;

@end

@implementation HDBConfig

/**
 * 单例
 */
+ (instancetype)defaultConfig {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[HDBConfig alloc] init];
        [_instance __initial];
    });
    return _instance;
}

/**
 * 设置debugLog模式
 */
+ (void)setDebugMode:(BOOL)isDebug {
#warning 待实现
    
}

/**
 * 设置数据存储路径,默认是Documents/HappyDatabase/
 */
+ (void)configPath:(NSString *)path {
    [HDBConfig defaultConfig].path = path;
}

#pragma mark - Primary Method

/**
 * 内部初始化方法
 */
- (void)__initial {
    _path = [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"HappyDatabase"] stringByAppendingPathComponent:@"Database.sqlite"];
}

@end
