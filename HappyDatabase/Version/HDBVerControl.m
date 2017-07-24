//
//  HDBVerControl.m
//  HappyDatabase
//
//  Created by Li on 2017/5/23.
//  Copyright © 2017年 Li. All rights reserved.
//

#import "HDBVerControl.h"
#import "HDBPlistHandle.h"
#import "HDBConfig.h"
#import "HDBVerUpdateItem.h"
#import "HDBManager+Extra.h"

static HDBVerControl *_instance = nil;

@interface HDBVerControl ()

/**
 * 数据同步处理类
 */
@property (nonatomic, strong) HDBPlistHandle *plistHandle;

/**
 * 待更新的配置信息
 */
@property (nonatomic, strong) NSMutableArray *updateVersionArray;
@end

@implementation HDBVerControl

/**
 * 单例
 */
+ (instancetype)sharedControl {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[HDBVerControl alloc] init];
        [_instance __initial];
    });
    return _instance;
}

/**
 * 检查是否需要更新本地数据库
 */
- (BOOL)needUpdateVersion {
    if (_plistHandle.info[@"Version"] == nil || [_plistHandle.info[@"Version"] compare:[self appVersion]] == NSOrderedAscending) {
        return YES;
    }
    return NO;
}

/**
 * 开始同步本地数据库到最新格式
 */
- (BOOL)beginUpdateVersion {
    BOOL result = YES;
    [_updateVersionArray sortUsingComparator:^NSComparisonResult(HDBVerUpdateItem *obj1, HDBVerUpdateItem *obj2) {
        return [obj1.version compare:obj2.version];
    }];
    for (HDBVerUpdateItem *item in _updateVersionArray) {
        BOOL ret = [[HDBManager sharedManager] updateTable:item.modelName parameters:item.parameters];
        if (!ret) {
            result = NO;
        }
    }
    [_plistHandle.info setObject:[self appVersion] forKey:@"Version"];
    [_plistHandle synchronize];
    return result;
}

/**
 * 设置数据库同步格式
 */
- (void)configModel:(NSString *)modelName version:(NSString *)version parameters:(NSDictionary *)parameters {
    if (_plistHandle.info[@"Version"] != nil && [_plistHandle.info[@"Version"] compare:version] == NSOrderedAscending) {
        NSArray *models = [[HDBManager sharedManager] queryAllTableNamesInDB];
        if ([models containsObject:modelName]) {
            HDBVerUpdateItem *item = [[HDBVerUpdateItem alloc] initWithModelName:modelName version:version parameters:parameters];
            [self.updateVersionArray addObject:item];
        }
    }
}

/**
 * HDB版本号
 */
- (NSString *)version {
    return @"1.0.0";
}

/**
 * App版本号
 */
- (NSString *)appVersion {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

#pragma mark - PrimaryMethod

/**
 * 内部初始化方法
 */
- (void)__initial {
    // Config propertys
    _plistHandle = [[HDBPlistHandle alloc] initWithFileName:@"HDBVerControl"];
    _updateVersionArray = [[NSMutableArray alloc] init];
}



@end
