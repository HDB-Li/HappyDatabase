//
//  HDBStorage.h
//  HappyDatabase
//
//  Created by Li on 2017/5/24.
//  Copyright © 2017年 Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HDBStorage : NSObject

/** 
 * 数据库内表单的集合
 */
@property (nonatomic, strong) NSMutableArray *tables;

/**
 * 数据库内表单的字段集合
 */
@property (nonatomic, strong) NSMutableDictionary *tableColumns;

/**
 * 单例
 */
+ (instancetype)sharedStorage;

/**
 * 存储一个模型的PrimaryKey和创建Table时的字段集
 */
- (BOOL)storageModel:(NSString *)modelName primaryKey:(NSString *)primaryKey allowedKeys:(NSArray *)allowedKeys ignoredKeys:(NSArray *)ignoredKeys;

/**
 * 是否注册过这个模型
 */
- (BOOL)isRegisterd:(NSString *)modelName;

/**
 * 获取模型的PrimaryKey
 */
- (NSString *)primaryKeyFromModel:(NSString *)modelName;

/**
 * 获取模型中已注册的Propertys
 */
- (NSArray <NSString *>*)storagedPropertysFromModel:(NSString *)modelName;

/**
 * 获取模型中的PrimaryValue,如果模型未注册,则返回nil
 */
- (id)primaryValueFromModel:(id)model;

@end
