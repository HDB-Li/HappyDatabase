//
//  HDBPlistHandle.h
//  HappyDatabase
//
//  Created by Li on 2017/5/23.
//  Copyright © 2017年 Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HDBPlistHandle : NSObject

/**
 * 数据字典
 */
@property (nonatomic, strong) NSMutableDictionary *info;

/**
 * 文件名称
 */
@property (nonatomic, copy, readonly) NSString *fileName;

/**
 * 指定的初始化方法
 */
- (instancetype)initWithFileName:(NSString *)fileName;

/**
 * 同步info到本地plist文件
 */
- (void)synchronize;

@end
