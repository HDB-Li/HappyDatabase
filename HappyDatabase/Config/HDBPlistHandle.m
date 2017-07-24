//
//  HDBPlistHandle.m
//  HappyDatabase
//
//  Created by Li on 2017/5/23.
//  Copyright © 2017年 Li. All rights reserved.
//

#import "HDBPlistHandle.h"
#import "HDBConfig.h"

@implementation HDBPlistHandle

/**
 * 初始化方法
 */
- (instancetype)initWithFileName:(NSString *)fileName {
    if (self = [super init]) {
        [self __initial];
        [self __configFileName:fileName];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self __initial];
    }
    return self;
}

/**
 * 同步数据到本地文件
 */
- (void)synchronize {
    @synchronized (self) {
        BOOL ret = [_info writeToFile:[self __filePathWithFileName:_fileName] atomically:YES];
        NSAssert(ret, @"synchronize versions info failed");
    }
}

#pragma mark - Primary Method

/**
 * 内部初始化方法
 */
- (void)__initial {
    _info = [[NSMutableDictionary alloc] init];
}

/**
 * 配置文件名
 */
- (void)__configFileName:(NSString *)fileName {
    [_info removeAllObjects];
    _fileName = fileName;
    NSDictionary *dictionary = [[NSDictionary alloc] initWithContentsOfFile:[self __filePathWithFileName:fileName]];
    if (dictionary) {
        [_info addEntriesFromDictionary:dictionary];
    }
}

/**
 * 完整的文件路径
 */
- (NSString *)__filePathWithFileName:(NSString *)fileName {
    return [[[HDBConfig defaultConfig].path stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"plist"];
}

@end
