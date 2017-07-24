//
//  HDBStorage.m
//  HappyDatabase
//
//  Created by Li on 2017/5/24.
//  Copyright © 2017年 Li. All rights reserved.
//

#import "HDBStorage.h"
#import "NSObject+HappyDatabase.h"
#import "HDBConfig.h"

static HDBStorage *_instance = nil;

@interface HDBStorage ()

@property (nonatomic, strong) NSMutableDictionary *propertyStorage;

@property (nonatomic, strong) NSMutableDictionary *primaryKeyStorage;

@end

@implementation HDBStorage

/**
 * 单例
 */
+ (instancetype)sharedStorage {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[HDBStorage alloc] init];
        [_instance __initial];
    });
    return _instance;
}

/**
 * 存储一个模型的PrimaryKey和创建Table时的字段集
 */
- (BOOL)storageModel:(NSString *)modelName primaryKey:(NSString *)primaryKey allowedKeys:(NSArray *)allowedKeys ignoredKeys:(NSArray *)ignoredKeys {
    Class aClass = NSClassFromString(modelName);
    NSArray *properties = [aClass HDB_properties];
    if (properties.count == 0) {
        HDBLog(@"Get class propertyNames fail,class = %@",modelName);
        return NO;
    }
    // Default is all propertys
    NSMutableArray *propertys = [[NSMutableArray alloc] initWithArray:properties];
    if (allowedKeys) {
        // Config if used allowedKeys
        for (NSString *key in allowedKeys) {
            if ([propertys containsObject:key] == NO) {
                HDBLog(@"AllowedKey is not in property,key = %@",key);
                return NO;
            }
        }
        [propertys removeAllObjects];
        [propertys addObjectsFromArray:allowedKeys];
    } else if (ignoredKeys) {
        // Config if used ignoredKeys
        for (NSString *key in ignoredKeys) {
            [propertys removeObject:key];
        }
    }
    
    // Judge primaryKey is exist
    if ([propertys containsObject:primaryKey] == NO) {
        HDBLog(@"Primary key is not exist");
        return NO;
    }
    // Storage infos
    [self __updateClass:modelName primaryKey:primaryKey propertys:propertys];
    return YES;
}

/**
 * 是否注册过这个模型
 */
- (BOOL)isRegisterd:(NSString *)modelName {
    return [_primaryKeyStorage.allKeys containsObject:modelName];
}

/**
 * 获取模型的PrimaryKey
 */
- (NSString *)primaryKeyFromModel:(NSString *)modelName {
    return _primaryKeyStorage[modelName];
}

/**
 * 获取模型中已注册的Propertys
 */
- (NSArray <NSString *>*)storagedPropertysFromModel:(NSString *)modelName {
    return _propertyStorage[modelName];
}

/**
 * 获取模型中的PrimaryValue,如果模型未注册,则返回nil
 */
- (id)primaryValueFromModel:(id)model {
    NSString *aClass = NSStringFromClass([model class]);
    NSString *key = [self primaryKeyFromModel:aClass];
    if (!key) {
        return nil;
    }
    return [model valueForKey:key];
}

#pragma mark - Primary Method

/**
 * 内部初始化方法
 */
- (void)__initial {
    _propertyStorage = [[NSMutableDictionary alloc] init];
    _primaryKeyStorage = [[NSMutableDictionary alloc] init];
    _tables = [[NSMutableArray alloc] init];
    _tableColumns = [[NSMutableDictionary alloc] init];
}

/**
 * 缓存表结构信息
 */
- (void)__updateClass:(NSString *)className primaryKey:(NSString *)primaryKey propertys:(NSArray *)propertys {
    [_propertyStorage setObject:propertys forKey:className];
    [_primaryKeyStorage setObject:primaryKey forKey:className];
}

@end
