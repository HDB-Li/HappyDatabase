//
//  HDBManager.m
//  HappyDatabase
//
//  Created by Li on 2017/5/23.
//  Copyright © 2017年 Li. All rights reserved.
//

#import "HDBManager.h"
#import "HDBManager+Extra.h"

#import "HDBConfig.h"
#import "HDBCountItem.h"
#import "HDBDefined.h"
#import "HDBConditionGroup.h"
#import "HDBStorage.h"

#import "NSString+HappyDatabase.h"
#import "NSObject+HappyDatabase.h"

#import <FMDB.h>
#import <objc/runtime.h>



/** TABLE */
static NSString *const CREATE_TABLE_SQLITE         =
@"CREATE TABLE IF NOT EXISTS %@ ( "HDB_kObjData" BLOB NOT NULL,";
static NSString *const CREATE_NORMAL_TABLE_SQLITE  =
@"CREATE TABLE IF NOT EXISTS %@ ( ";
static NSString *const CREATE_DEFAULT_TABLE_SQLITE =
@"CREATE TABLE IF NOT EXISTS %@ (\
id TEXT NOT NULL, \
"HDB_kObjData" BLOB NOT NULL, \
"HDB_kTimeStamp" TEXT NOT NULL, \
PRIMARY KEY(id))";

/** SQLite */
static NSString *const CREATE_SUBTABLE_SQLITE = @"CREATE TABLE IF NOT EXISTS %@ ( id integer PRIMARY KEY AUTOINCREMENT NOT NULL, ";
static NSString *const PRIMARY_KEY_SQLITE     = @"PRIMARY KEY ( %@ )";
static NSString *const DROP_TABLE             = @"DROP TABLE %@";
static NSString *const CLEAR_TABLE            = @"DELETE FROM %@";
static NSString *const QUERY_ALL_COLUMN       = @"PRAGMA table_info( %@ )";
static NSString *const QUERY_ALL_TABLES_IN_DB = @"SELECT name FROM sqlite_master WHERE type='table' order by name;";

/** ITEM */
static NSString *const INSERT_DEFAULT_OBJ     = @"INSERT INTO %@ (id, "HDB_kObjData", "HDB_kTimeStamp") VALUES (?, ?, ?)";
static NSString *const INSERT_OBJ             = @"INSERT INTO %@ ";
static NSString *const DELETE_DEFAULT_OBJ     = @"DELETE FROM %@ WHERE id = ?";
static NSString *const DELETE_OBJ             = @"DELETE FROM %@ ";
static NSString *const SELECT_DEFAULT_OBJ     = @"SELECT * FROM %@ WHERE id = ? Limit 1";
static NSString *const SELECT_OBJ             = @"SELECT * FROM %@ ";
static NSString *const UPDATE_DEFAULT_OBJ     = @"REPLACE INTO %@ (id, "HDB_kObjData", "HDB_kTimeStamp") VALUES (?, ?, ?)";
static NSString *const UPDATE_OBJ             = @"UPDATE %@ SET";
static NSString *const REPLACE_OBJ            = @"REPLACE INTO %@ ";
static NSString *const QUERY_ALL_OBJ          = @"SELECT %@ FROM %@";
static NSString *const QUERY_ALL_DEFAULT_OBJ  = @"SELECT * FROM %@";
static NSString *const COUNT_ALL_DEFAULT_OBJ  = @"SELECT COUNT(*) AS NUM FROM %@";

static HDBManager *_instance = nil;

@interface HDBManager ()

@property (nonatomic, strong) FMDatabaseQueue *dbQueue; /** DBqueue */

@property (nonatomic, strong) HDBStorage *storage;

@property (nonatomic, copy) NSString *currentDBName;

@end

@implementation HDBManager

#pragma mark - Public Method
#pragma mark - Initial

/**
 * 单例
 */
+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[HDBManager alloc] init];
        [_instance __initial];
        HDBLog(@"Initial success");
    });
    return _instance;
}

/**
 * 注册需要创建的模型
 */
- (BOOL)registerClass:(NSString *)modelName primaryKey:(NSString *)primaryKey allowedKeys:(NSArray *)allowedKeys ignoredKeys:(NSArray *)ignoredKeys {
    if ([self __isConformsToNSCodingProtocol:modelName] == NO) {
        HDBLog(@"Register class fail, class isn't conform NSCoding, class = %@",modelName);
        return NO;
    }
    if ([_storage storageModel:modelName primaryKey:primaryKey allowedKeys:allowedKeys ignoredKeys:ignoredKeys] == NO) {
        return NO;
    }
    
    return [self __createModelTableWithClassName:modelName];
}

#pragma mark - Insert

/**
 * 插入一个模型数据.
 */
- (BOOL)insertModel:(id<NSCoding>)model {
    return [self __insertModel:model owner:HDB_kOwnerSelf autoUpDate:NO];
}

#pragma mark - Drop

/**
 * 删除一个模型数据.
 */
- (BOOL)deleteModel:(id<NSCoding>)model {
    return [self __deleteModel:model owner:HDB_kOwnerSelf];
}

/**
 * 根据一个关键值去删除模型.
 */
- (BOOL)deleteModel:(NSString *)modelClass primaryValue:(id)primaryValue {
    NSString *primary = [_storage primaryKeyFromModel:modelClass];
    NSDictionary *parameters = @{primary:primaryValue};
    return [self deleteModel:modelClass parameters:parameters];
}

/**
 * 根据一个属性名/值字典去删除模型
 */
- (BOOL)deleteModel:(NSString *)modelClass parameters:(NSDictionary *)parameters {
    NSArray *models = [self queryModels:modelClass parameters:parameters];
    BOOL result = YES;
    for (id model in models) {
        BOOL ret = [self deleteModel:model];
        if (ret == NO) {
            result = NO;
        }
    }
    return result;
}

#pragma mark - Update

/**
 * 同步一个模型数据,没有则创建.
 */
- (BOOL)updateModel:(id<NSCoding>)model {
    return [self __updateModel:model owner:HDB_kOwnerSelf];
}

/**
 * 修改一个模型的PrimaryValue,同时同步所有关联关系.
 */
- (BOOL)updateModel:(id)model oriPrimaryValue:(id)oriPrimaryValue {
    // Check base infos
    NSString *table = NSStringFromClass([model class]);
    if ([self __checkTableName:table] == NO) {
        return NO;
    }
    
    if (!oriPrimaryValue) {
        HDBLog(@"ChangeModel fail, oriPrimaryKey is nil");
        return NO;
    }
    
    if ([oriPrimaryValue isEqual:[_storage primaryValueFromModel:model]]) {
        HDBLog(@"ChangeModel fail, oriPrimaryKey is same to model's primaryKey");
        return NO;
    }
    
    // Get model from table
    id modelExist = [self queryModel:table primaryValue:oriPrimaryValue];
    // Check model is exist
    if (!modelExist) {
        HDBLog(@"ChangeModel fail,originalModel is not exist,exchangeModel:%@,originalPrimaryValue = %@",model,oriPrimaryValue);
        return NO;
    }
    
    
    // 先更新父类
    // Get original ownerString
    NSString *oriOwnerString = [self __getOwnerStringFromModel:modelExist];
    // Components to original owners
    NSArray *oriOwners      = [self __getOriginalOwnerArrayFromOwnerString:oriOwnerString];
    // Get items
    NSArray *items = [self __convertToCountItemsByOwners:oriOwners];
    for (HDBCountItem *item in items) {
        if (item.isSelf == NO) {
            id obj = [self queryModel:item.parent primaryValue:item.parentKey];
            if (obj) {
                [obj setValue:model forKey:item.name];
                [self __updateModel:obj owner:nil];
            }
        }
    }
    
    
    [self deleteModel:modelExist];
    
    return [self updateModel:model];
}

#pragma mark - Query

/**
 * 根据PrimaryValue查询一个模型,不存在则返回nil
 */
- (id)queryModel:(NSString *)modelClass primaryValue:(id)primaryValue {
    if ([self __checkTableName:modelClass] == NO) {
        return nil;
    }
    NSString *key = [_storage primaryKeyFromModel:modelClass];
    if (key.HDB_isExist == NO || !primaryValue) {
        return nil;
    }
    NSArray *models = [self queryModels:modelClass parameters:@{key:primaryValue}];
    if (models.count == 0) {
        return nil;
    }
    return [models firstObject];
}

/**
 * 查询一组符合条件的模型集合
 */
- (NSArray *)queryModels:(NSString *)modelClass parameters:(NSDictionary *)parameters {
    NSMutableArray *keys = [[NSMutableArray alloc] initWithArray:parameters.allKeys];
    [keys sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    
    NSMutableArray *arguments = [[NSMutableArray alloc] init];
    for (NSString *key in keys) {
        [arguments addObject:parameters[key]];
    }
    __block NSString *SQLite = [SELECT_OBJ stringByAppendingString:[self __selectModelSQLiteWithModelClass:modelClass arguments:arguments]];
    SQLite = [NSString stringWithFormat:SQLite,modelClass];
    __block NSMutableArray *objects = [[NSMutableArray alloc] init];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:SQLite withArgumentsInArray:arguments];
        while ([set next]) {
            NSData *data = [set dataForColumn:HDB_kObjData];
            if (data) {
                id object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                if ([object isKindOfClass:NSClassFromString(modelClass)]) {
                    [objects addObject:object];
                }
            }
        }
    }];
    return objects;
}

/**
 * 查询一组符合条件的模型集合
 */
- (NSArray *)queryModels:(NSString *)modelClass HDBConditions:(id<HDBConditionInput>)condition {
    NSString *SQLite = [SELECT_OBJ stringByAppendingFormat:@" WHERE %@;",[condition SQLiteString]];
    SQLite = [NSString stringWithFormat:SQLite,modelClass];
    return [self queryModels:modelClass SQLiteString:SQLite arguments:nil];
}

/**
 * 根据SQLite语句查询一组符合条件的模型集合
 */
- (NSArray *)queryModels:(NSString *)modelClass SQLiteString:(NSString *)SQLite arguments:(NSArray *)arguments {
    __block NSMutableArray *objects = [[NSMutableArray alloc] init];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:SQLite withArgumentsInArray:arguments];
        while ([set next]) {
            NSData *data = [set dataForColumn:HDB_kObjData];
            if (data) {
                id object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                if ([object isKindOfClass:NSClassFromString(modelClass)]) {
                    [objects addObject:object];
                }
            }
        }
    }];
    return objects;
}

#pragma mark - Table Method

/**
 * 删除一个表
 */
- (BOOL)dropTable:(NSString *)tableName {
    if ([self __checkTableName:tableName] == NO) {
        HDBLog(@"Drop table failed, tableName is nil");
        return NO;
    }
    if ([[self queryAllTableNamesInDB] containsObject:tableName] == NO) {
        return YES;
    }
    NSString *SQLite = [NSString stringWithFormat:DROP_TABLE,tableName];
    BOOL result = [self __executeUpdateSQLite:SQLite arguments:nil];
    if (result) {
        [_storage.tables removeObject:tableName];
    }
    return result;
}

/**
 * 清除表中内所有数据
 */
- (BOOL)clearTable:(NSString *)tableName {
    if ([self __checkTableName:tableName] == NO) {
        HDBLog(@"Clear table failed, tableName is nil");
        return NO;
    }
    NSString *SQLite = [NSString stringWithFormat:CLEAR_TABLE,tableName];
    return [self __executeUpdateSQLite:SQLite arguments:nil];
}

/**
 * 获取一个表内数据的数量
 */
- (NSUInteger)countFromTable:(NSString *)tableName {
    if ([self __checkTableName:tableName] == NO) {
        HDBLog(@"Query all objectsCount failed, tableName is nil");
        return 0;
    }
    NSString * SQLite = [NSString stringWithFormat:COUNT_ALL_DEFAULT_OBJ,tableName];
    __block NSInteger num = 0;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        num = [db intForQuery:SQLite];
    }];
    return num;
}

/**
 * 获取当前Database中的所有表
 */
- (NSArray *)queryAllTableNamesInDB {
    if (_storage.tables.count > 0) {
        return _storage.tables;
    }
    __block NSMutableArray *names = [[NSMutableArray alloc] init];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:QUERY_ALL_TABLES_IN_DB];
        while ([set next]) {
            NSString *name = [set stringForColumn:@"name"];
            [names addObject:name];
        }
    }];
    [_storage.tables removeAllObjects];
    [_storage.tables addObjectsFromArray:names];
    return names;
}

#pragma mark - Private Method
#pragma mark - Initial

/**
 * 内部初始化方法
 */
- (void)__initial {
    [self setUpDatabaseWithName:@"database"];
}

/**
 * 判断是否遵守了<NSCoding>协议.
 */
- (BOOL)__isConformsToNSCodingProtocol:(NSString *)className {
    Class aClass = NSClassFromString(className);
    if ([aClass conformsToProtocol:@protocol(NSCoding)] == NO) {
        HDBLog(@"Class isn't write conforms <NSCoding>,may be you need write <NSCoding> in %@.h",className);
    }
    
    id model = [aClass new];
    if ([model respondsToSelector:@selector(encodeWithCoder:)] && [model respondsToSelector:@selector(initWithCoder:)]) {
        return YES;
    }
    
    return NO;
}

#pragma mark - Table Method

/**
 * 创建一个模型表,采用注册时的配置方案
 */
- (BOOL)__createModelTableWithClassName:(NSString *)className {
    return [self __createModelTableWithClassName:className propertys:nil];
}

/**
 * 创建一个模型表,采用指定的配置方案
 */
- (BOOL)__createModelTableWithClassName:(NSString *)className propertys:(NSArray *)propertys {
    if ([self __checkTableName:className] == NO) {
        HDBLog(@"Insert table failed, tableName is nil");
        return NO;
    }
    if ([[self queryAllTableNamesInDB] containsObject:className]) {
// 这里或许应该加上判断,当前table的column是否和要注册的propertys一致.
        return YES;
    }
    NSString *SQLite = [self __createModelTableSQLiteWithModelName:className propertys:propertys];
    BOOL result = [self __executeUpdateSQLite:SQLite arguments:nil];
    if (result) {
        [_storage.tables addObject:className];
    }
    return result;
}

#pragma mark - Insert / Drop / Update / Query

/**
 * 插入一个带引用计数的模型模型数据(内部使用)

 @param model 模型
 @param owner 引用计数来源
 @param autoUpdate 是否强制更新数据,YES:数据存在则更新,不存在则创建. NO:数据存在则返回NO,不存在则创建
 */
- (BOOL)__insertModel:(id)model owner:(NSString *)owner autoUpDate:(BOOL)autoUpdate {
    NSString *table = NSStringFromClass([model class]);
    if ([self __checkTableName:table] == NO) {
        return NO;
    }
    
    // Get primary value in model
    id primaryValue = [_storage primaryValueFromModel:model];
    // Get model from table
    id modelExist = [self queryModel:table primaryValue:primaryValue];
    // Get original ownerString
    NSString *oriOwnerString = [self __getOwnerStringFromModel:model];
    // Components to original owners
    NSArray *oriOwners      = [self __getOriginalOwnerArrayFromOwnerString:oriOwnerString];
    // Get real owners
    //    NSArray *owners = [self queryOwnersFromOriginalOwners:oriOwners];
    
    if (autoUpdate == NO) {
        // 不是强制更新
        if (modelExist && owner && [oriOwners containsObject:owner]) {
            HDBLog(@"Model is already exist, use 'update' instead of 'insert'");
            return NO;
        }
    }
    
    NSMutableArray *arguments = [[NSMutableArray alloc] init];
    NSArray *columns = [self __queryAllColumnInTable:table];
    for (NSString *key in columns) {
        id value = [model valueForKey:key];
        if (value) {
            HDBCountItem *item = [HDBCountItem itemWithParent:table name:key parentKey:primaryValue];
            [arguments addObject:[self __updatePropertyModel:value HRCItem:item]];
        } else {
            [arguments addObject:@""];
        }
    }
    
    if (owner) {
        NSArray *newOwners = [self __insertOrDelete:YES newOwner:owner intoOriginalOwners:oriOwners];
        NSString *newOwnerString = [self __getOwnerStringWithOwnerArray:newOwners];
        [arguments addObject:newOwnerString];
    } else {
        [arguments addObject:oriOwnerString];
    }
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:model];
    [arguments addObject:data?:@""];
    NSString *SQLite = [NSString stringWithFormat:[REPLACE_OBJ stringByAppendingString:[self __insertModelSQLiteWithModel:model]],table];
    
    BOOL result = [self __executeUpdateSQLite:SQLite arguments:arguments];
    return  result;
}

/**
 * 更新模型的引用计数(内部使用)
 */
- (BOOL)__updateModel:(id)model owner:(NSString *)owner {
    id originalModel = [self queryModel:NSStringFromClass([model class]) primaryValue:[_storage primaryValueFromModel:model]];
    if (originalModel) {
        [self __deleteModel:originalModel owner:owner];
    }
    return [self __insertModel:model owner:owner autoUpDate:YES];
}

#pragma mark - SQLite
/**
 * 返回创建表的SQLite语句
 */
- (NSString *)__createModelTableSQLiteWithModelName:(NSString *)modelName propertys:(NSArray *)propertys {
    if (propertys == nil) {
        propertys = [_storage storagedPropertysFromModel:modelName];
    }
    NSString *primaryKey = [_storage primaryKeyFromModel:modelName];
    NSMutableString *SQLite = [[NSMutableString alloc] initWithString:CREATE_TABLE_SQLITE];
    
    for (NSString *name in propertys) {
        NSString *type = @"TEXT"; // config with property.type
        [SQLite appendFormat:@"%@ %@ DEFAULT '',",name,type];
    }
    
    [SQLite appendFormat:@"%@ TEXT DEFAULT '',",HDB_kOwner];
    [SQLite appendFormat:PRIMARY_KEY_SQLITE,primaryKey];
    [SQLite appendString:@");"];
    return [NSString stringWithFormat:SQLite,modelName];
}

#pragma mark - 引用计数
/**
 * 获取到表中的原始引用计数文字
 */
- (NSString *)__getOwnerStringFromModel:(id)model {
    NSString *table = NSStringFromClass([model class]);
    if ([self __checkTableName:table] == NO) {
        HDBLog(@"query owner failed, table is nil");
        return nil;
    }
    
    NSString *primaryKey = [_storage primaryKeyFromModel:table];
    __block NSString *SQLite = [NSString stringWithFormat:[QUERY_ALL_OBJ stringByAppendingString:[self __selectModelSQLiteWithModelClass:table arguments:@[primaryKey]]],HDB_kOwner,table];
    __block NSArray *arguments = @[[model valueForKey:primaryKey]];
    __block NSString *owner = nil;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:SQLite withArgumentsInArray:arguments];
        while ([set next]) {
            owner = [set stringForColumn:HDB_kOwner];
        }
    }];
    return owner;
}

/**
 * 将引用计数文字分割成数组
 */
- (NSArray *)__getOriginalOwnerArrayFromOwnerString:(NSString *)ownerString {
    return [ownerString componentsSeparatedByString:@","];
}

/**
 * 将字符串转化成HDBCountItem
 */
- (NSArray <HDBCountItem *>*)__convertToCountItemsByOwners:(NSArray *)originalOwners {
    NSMutableArray *items = [[NSMutableArray alloc] init];
    for (NSString *owner in originalOwners) {
        HDBCountItem *item = [owner HDB_convertToCountItem];
        if (item) {
            [items addObject:item];
        } else {
            HDBLog(@"Convert to HRCItem failed when conponents separate,string = %@",owner);
        }
    }
    return items;
}

/**
 * 将一个新的引用计数 插入旧数组/从旧数组中删除.
 */
- (NSArray *)__insertOrDelete:(BOOL)isInsert newOwner:(NSString *)owner intoOriginalOwners:(NSArray *)originalOwners {
    NSMutableArray *newOwners = [[NSMutableArray alloc] initWithArray:originalOwners];
    if (isInsert) {
        if ([originalOwners containsObject:owner] == NO) {
            [newOwners addObject:owner];
        }
    } else {
        [newOwners removeObject:owner];
    }
    return newOwners;
}

/**
 * 将一个引用计数数组,拼接成字符串.
 */
- (NSString *)__getOwnerStringWithOwnerArray:(NSArray *)ownerArray {
    NSMutableArray *owners = [[NSMutableArray alloc] initWithArray:ownerArray];
    [owners removeObject:@""];
    return [owners componentsJoinedByString:@","];
}

#pragma mark - 同步更新子模型
/**
 * 更新一个属性的引用计数,如果是注册过的模型,则自动更新引用计数,如果不是模型则直接插入[model descripction],如果数组/字典中包含模型,也会同步更新引用计数.
 */
- (id)__updatePropertyModel:(id)model HRCItem:(HDBCountItem *)item {
    NSString *aClass = NSStringFromClass([model class]);
    if ([model isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (id value in model) {
            NSInteger index = [model indexOfObject:value];
            HDBCountItem *valueItem = [HDBCountItem itemWithParent:item.parent name:item.name parentKey:item.parentKey arrayIndex:index];
            [array addObject:[self __updatePropertyModel:value HRCItem:valueItem] ?: @""];
        }
        return array;
    } else if ([model isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        for (NSString *key in model) {
            id value = [model objectForKey:key];
            HDBCountItem *valueItem = [HDBCountItem itemWithParent:item.parent name:item.name parentKey:item.parentKey dictionaryKey:key];
            [dic setObject:[self __updatePropertyModel:value HRCItem:valueItem] forKey:key];
        }
        return dic;
    } else if ([_storage isRegisterd:aClass]) {
        return [self __updateSubModel:model HRCItem:item];
    }
    return model;
}

/**
 * 更新一个属性的引用计数(属性为注册过的模型)
 */
- (id)__updateSubModel:(id)model HRCItem:(HDBCountItem *)item {
    NSString *aClass = NSStringFromClass([model class]);
    // 先判断在对应的表里是否存在这个对象
    NSString *primaryKey = [_storage primaryKeyFromModel:aClass];
    id primaryValue = [model valueForKey:primaryKey];
    id object = [self queryModel:aClass primaryValue:primaryValue];
    if (object) {
        // 存在过, 更新引用系数
        [self __insertModel:model owner:item.countItemString autoUpDate:YES];
    } else {
        // 不存在, 添加新的
        [self __insertModel:model owner:item.countItemString autoUpDate:YES];
    }
    return primaryValue;
}

#pragma mark - Tool

/**
 * 执行Update SQLite语句.
 */
- (BOOL)__executeUpdateSQLite:(NSString *)SQLite arguments:(NSArray *)array {
    __block BOOL result = NO;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:SQLite withArgumentsInArray:array];
    }];
    if (result == NO) {
        HDBLog(@"ExecuteUpdate fail, sql = %@,arguments = %@",SQLite,array);
    }
    return result;
}

/**
 * 检查表名.
 */
- (BOOL)__checkTableName:(NSString *)tableName {
    return tableName.HDB_isExist;
}

/**
 * 获取一个表中的所有字段
 */
- (NSArray *)__queryAllColumnInTable:(NSString *)tableName {
    if ([self __checkTableName:tableName] == NO) {
        HDBLog(@"QueryAllColumn failed, tableName is nil");
        return nil;
    }
    if ([_storage.tableColumns.allKeys containsObject:tableName]) {
        if ([_storage.tableColumns[tableName] count] > 0) {
            return _storage.tableColumns[tableName];
        }
    }
  
    __block NSString *SQLite = [NSString stringWithFormat:QUERY_ALL_COLUMN,tableName];
    __block NSMutableArray *objects = [[NSMutableArray alloc] init];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:SQLite withArgumentsInArray:nil];
        while ([set next]) {
            NSString *name = [set stringForColumn:@"name"];
            if (name) {
                [objects addObject:name];
            }
        }
    }];
    
    [objects removeObject:HDB_kObjData];
    [objects removeObject:HDB_kOwner];
    
    [objects sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    if (objects.count > 0) {
        [_storage.tableColumns setObject:objects forKey:tableName];
    }
    return objects;
}

/**
 * 删除一个子属性(普通属性+自定义模型属性)
 */
- (id)__deletePropertyModel:(id)model HRCItem:(HDBCountItem *)item {
    NSString *aClass = NSStringFromClass([model class]);
    if ([model isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (id value in model) {
            NSInteger index = [model indexOfObject:value];
            HDBCountItem *valueItem = [HDBCountItem itemWithParent:item.parent name:item.name parentKey:item.parentKey arrayIndex:index];
            [array addObject:[self __deletePropertyModel:value HRCItem:valueItem] ?: @""];
        }
        return array;
    } else if ([model isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        for (NSString *key in model) {
            id value = [model objectForKey:key];
            HDBCountItem *valueItem = [HDBCountItem itemWithParent:item.parent name:item.name parentKey:item.parentKey dictionaryKey:key];
            [dic setObject:[self __deletePropertyModel:value HRCItem:valueItem] ?: @"" forKey:key];
        }
        return dic;
    } else if ([_storage isRegisterd:aClass]) {
        return [self __deleteSubModel:model HRCItem:item];
    }
    return model;
}

/**
 * 删除一个子属性是自定义模型的数据(自定义模型属性)
 */
- (id)__deleteSubModel:(id)model HRCItem:(HDBCountItem *)item {
    NSString *aClass = NSStringFromClass([model class]);
    NSString *primaryKey = [_storage primaryKeyFromModel:aClass];
    id primaryValue = [model valueForKey:primaryKey];
    id object = [self queryModel:aClass primaryValue:primaryValue];
    if (object) {
        // 存在过, 更新引用系数
        [self __deleteModel:model owner:item.countItemString];
    } else {
        // 不存在, 添加新的
        [self __deleteModel:model owner:item.countItemString];
    }
    return primaryValue;
}

#pragma mark - Tool

/**
 * 插入数据SQLite的后半段
 */
- (NSString *)__insertModelSQLiteWithModel:(id)model {
    NSString *table = NSStringFromClass([model class]);
    NSArray *columns = [self __queryAllColumnInTable:table];
    NSMutableString *SQLite1 = [[NSMutableString alloc] initWithString:@" ("];
    NSMutableString *SQLite2 = [[NSMutableString alloc] initWithString:@" VALUES ("];

    for (NSString *key in columns) {
        [SQLite1 appendFormat:@" %@,",key];
        [SQLite2 appendFormat:@" ?,"];
    }
    
    
    [SQLite1 appendFormat:@" %@,",HDB_kOwner];
    [SQLite2 appendString:@" ?,"];
    [SQLite1 appendFormat:@" %@",HDB_kObjData];
    [SQLite2 appendString:@" ?"];
    
    [SQLite1 appendString:@" )"];
    [SQLite1 appendString:SQLite2];
    [SQLite1 appendString:@" );"];
    return SQLite1;
}

/**
 * 筛选条件SQLite
 */
- (NSString *)__selectModelSQLiteWithModelClass:(NSString *)modelClass arguments:(NSArray *)arguments {
    NSMutableString *SQLite = [[NSMutableString alloc] initWithString:@" WHERE "];
    for (NSString *key in arguments) {
        [SQLite appendFormat:@" %@ = ? AND",key];
    }
    
    if ([[SQLite substringFromIndex:SQLite.length - 3] isEqualToString:@"AND"]) {
        [SQLite deleteCharactersInRange:NSMakeRange(SQLite.length - 3, 3)];
    }
    
    [SQLite appendString:@" ;"];
    return SQLite;
}

#pragma mark - Others

/**
 * 删除一个模型的引用,如果还存在其他引用,则不删除数据,如果没有其他引用,则同时删除数据
 */
- (BOOL)__deleteModel:(id)model owner:(NSString *)owner {
    
    // Check base infos
    NSString *table = NSStringFromClass([model class]);
    if ([self __checkTableName:table] == NO) {
        return NO;
    }
    if (owner.HDB_isExist == NO) {
        HDBLog(@"Delete fail, owner is nil");
        return NO;
    }
    
    NSString *primaryKey = [_storage primaryKeyFromModel:table];
    // Get primary value in model
    id primaryValue = [_storage primaryValueFromModel:model];
    // Get model from table
    id modelExist = [self queryModel:table primaryValue:primaryValue];
    // Check model is exist
    if (!modelExist) {
        HDBLog(@"Delete fail, model:%@ is not in table",model);
        return NO;
    }
    
    // Get original ownerString
    NSString *oriOwnerString = [self __getOwnerStringFromModel:model];
    // Components to original owners
    NSArray *oriOwners      = [self __getOriginalOwnerArrayFromOwnerString:oriOwnerString];
    // Get real owners
//    NSArray *owners = [self queryOwnersFromOriginalOwners:oriOwners];
    // Check model contains owner
    if ([oriOwners containsObject:owner] == NO) {
        HDBLog(@"Delete fail, model:%@, owners:%@ do not contain owner:%@",model,oriOwners,owner);
        return NO;
    }
    
    NSMutableArray *arguments = [[NSMutableArray alloc] init];
    // Get all columns from modelTable
    NSArray *columns = [self __queryAllColumnInTable:table];
    for (NSString *key in columns) {
        id value = [model valueForKey:key];
        if (value) {
            HDBCountItem *item = [HDBCountItem itemWithParent:table name:key parentKey:primaryValue];
            [arguments addObject:[self __deletePropertyModel:value HRCItem:item]];
        } else {
            [arguments addObject:@""];
        }
    }
    
    NSArray *newOwners = [self __insertOrDelete:NO newOwner:owner intoOriginalOwners:oriOwners];
    NSString *newOwnerString = [self __getOwnerStringWithOwnerArray:newOwners];
    [arguments addObject:newOwnerString];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:model];
    [arguments addObject:data?:@""];
    
    NSString *SQLite;
    if (newOwners.count > 0) {
        SQLite = [NSString stringWithFormat:[REPLACE_OBJ stringByAppendingString:[self __insertModelSQLiteWithModel:model]],table];
    } else {
        SQLite = [NSString stringWithFormat:[DELETE_OBJ stringByAppendingString:[self __selectModelSQLiteWithModelClass:table arguments:@[primaryKey]]],table];
        [arguments removeAllObjects];
        [arguments addObject:primaryValue];
    }
    
    BOOL result = [self __executeUpdateSQLite:SQLite arguments:arguments];
    return  result;
}

@end

#pragma mark - (DefaultTable) 默认格式的表
@implementation HDBManager (DefaultTable)

/**
 * 创建一个默认格式的表
 */
- (BOOL)registerDefaultTableWithName:(NSString *)tableName {
#warning 这里应该改一下table的名字
    if ([self __checkTableName:tableName] == NO) {
        HDBLog(@"Insert table failed, tableName is nil");
        return NO;
    }
    NSString *SQLite = [NSString stringWithFormat:CREATE_DEFAULT_TABLE_SQLITE,tableName];
    return [self __executeUpdateSQLite:SQLite arguments:nil];
}


/**
 * 删除一个默认格式的表
 */
- (BOOL)dropDefaultTable:(NSString *)tableName {
#warning 这里应该改一下table的名字
    return [self dropTable:tableName];
}

/**
 * 插入一个Object
 */
- (BOOL)insertObject:(id<NSCoding>)object identify:(NSString *)identify table:(NSString *)tableName {
#warning 这里应该改一下table的名字
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
    NSString *timeStamp = [self __timeStampWithDate:[NSDate date]];
    NSString *SQLite = [NSString stringWithFormat:INSERT_DEFAULT_OBJ,tableName];
    if (!identify || !data || !timeStamp || !tableName) {
        HDBLog(@"Insert object fail, identify/data/timeStamp/tableName maybe is nil");
        return NO;
    }
    NSArray *arguments = @[identify,data,timeStamp];
    return [self __executeUpdateSQLite:SQLite arguments:arguments];
}


/**
 * 删除一个Object
 */
- (BOOL)deleteObjectWithIdentify:(NSString *)identify table:(NSString *)tableName {
#warning 这里应该改一下table的名字
    if (!identify || !tableName) {
        HDBLog(@"Delete object fail, identify/tableName maybe is nil");
        return NO;
    }
    NSString *SQLite = [NSString stringWithFormat:DELETE_DEFAULT_OBJ,tableName];
    NSArray *arguments = @[identify];
    return [self __executeUpdateSQLite:SQLite arguments:arguments];
}

/**
 * 修改一个Object数据,没有则添加一条数据
 */
- (BOOL)updateObject:(id<NSCoding>)object identify:(NSString *)identify table:(NSString *)tableName {
#warning 这里应该改一下table的名字
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
    NSString *timeStamp = [self __timeStampWithDate:[NSDate date]];
    NSString *SQLite = [NSString stringWithFormat:UPDATE_DEFAULT_OBJ,tableName];
    if (!identify || !data || !timeStamp || !tableName) {
        HDBLog(@"Insert object fail, identify/data/timeStamp/tableName maybe is nil");
        return NO;
    }
    NSArray *arguments = @[identify,data,timeStamp];
    return [self __executeUpdateSQLite:SQLite arguments:arguments];
}

/**
 * 查询一个Object
 */
- (id)queryObjectWithIdentify:(NSString *)identify table:(NSString *)tableName {
#warning 这里应该改一下table的名字
    if (!identify) {
        HDBLog(@"HHFMDBManager query object fail, identify/tableName is nil");
        return nil;
    }
    __block NSString *SQLite = [NSString stringWithFormat:SELECT_DEFAULT_OBJ,tableName];
    __block NSArray *arguments = @[identify];
    __block NSData *data = nil;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:SQLite withArgumentsInArray:arguments];
        while ([set next]) {
            data = [set dataForColumn:HDB_kObjData];
        }
    }];
    id object = nil;
    if (data) {
        object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    return object;
}

/**
 * 查询表中所有的Object
 */
- (NSArray *)queryAllObjectsFromDefaultTable:(NSString *)tableName {
#warning 这里应该改一下table的名字
    if ([self __checkTableName:tableName] == NO) {
        HDBLog(@"Query all objects failed, tableName is nil");
        return nil;
    }
    
    __block NSString *SQLite = [NSString stringWithFormat:QUERY_ALL_DEFAULT_OBJ,tableName];
    __block NSMutableArray *objects = [[NSMutableArray alloc] init];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:SQLite withArgumentsInArray:nil];
        while ([set next]) {
            NSData *data = [set dataForColumn:HDB_kObjData];
            if (data) {
                id object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                if (object) {
                    [objects addObject:object];
                }
            }
        }
    }];
    
    return objects;
}

/**
 * 时间戳工具
 */
- (NSString *)__timeStampWithDate:(NSDate *)date {
    static NSDateFormatter *formatter;
    if (formatter == nil) {
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    }
    return [formatter stringFromDate:date];
}

@end

#pragma mark - (Database) 多数据库相关操作
@implementation HDBManager (Database)

/**
 * 更改当前操作的数据库,如果不存在这个数据库,会自动创建并设为当前操作的数据库
 */
- (BOOL)setUpDatabaseWithName:(NSString *)dbName {
    if ([self __canAddDatabase:dbName] == NO) {
        return NO;
    }
    FMDatabaseQueue *queue = [self __queueWithDatabaseName:dbName];
    if (queue) {
        [self __setupCurrentDatabase:dbName];
        return YES;
    }
    [self __addDatabaseQueueWithName:dbName];
    return YES;
}

#pragma mark - Primary Method

/**
 * 判断是否数据库名字是否合法
 */
- (BOOL)__canAddDatabase:(NSString *)dbName {
    if (!dbName.HDB_isExist) {
        HDBLog(@"Add Database fail, reason:dbName is empty");
        return NO;
    }
    return YES;
}

/**
 * 查询是否存在对应的数据库
 */
- (FMDatabaseQueue *)__queueWithDatabaseName:(NSString *)dbName {
    dbName = [@"DatabaseQueue" stringByAppendingString:dbName];
    FMDatabaseQueue *queue = objc_getAssociatedObject(self, [dbName UTF8String]);
    return queue;
}

/**
 * 创建Queue
 */
- (void)__addDatabaseQueueWithName:(NSString *)dbName {
    NSString *fileName = [dbName stringByAppendingPathExtension:@"sqlite"];
    NSString *dbPath = [[HDBConfig defaultConfig].path stringByAppendingPathComponent:fileName];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [self __insertDatabaseQueue:queue databaseName:dbName];
    [self __setupCurrentDatabase:dbName];
}

/**
 * 记录Queue
 */
- (void)__insertDatabaseQueue:(FMDatabaseQueue *)queue databaseName:(NSString *)dbName{
    dbName = [@"DatabaseQueue" stringByAppendingString:dbName];
    objc_setAssociatedObject(self, [dbName UTF8String], queue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    HDBLog(@"%@", [NSString stringWithFormat:@"insert queue with Name = %@",dbName]);
}

/**
 * 设置当前Queue
 */
- (void)__setupCurrentDatabase:(NSString *)dbName {
    HDBLog(@"Set up new database,dbName = %@",dbName);
    dbName = [@"DatabaseQueue" stringByAppendingString:dbName];
    FMDatabaseQueue *queue = [self __queueWithDatabaseName:dbName];
    _dbQueue = queue;
    _currentDBName = dbName;
}

@end

#pragma mark - (Internal) 内部调用方法
@implementation HDBManager (Internal)

/**
 * 内部方法 用于同步新旧数据库内字段名更改
 */
- (BOOL)updateTable:(NSString *)modelClass parameters:(NSDictionary *)parameters {
    BOOL ret0 = [self __dropTempTable:modelClass];
    NSArray *oldColumn = [self __queryAllColumnInTable:modelClass];
    NSMutableArray *propertys = [[NSMutableArray alloc] initWithArray:oldColumn];
    for (int i = 0; i < propertys.count; i++) {
        NSString *key = propertys[i];
        if ([parameters.allKeys containsObject:key]) {
            [propertys replaceObjectAtIndex:i withObject:parameters[key]];
        }
    }
    BOOL ret1 = [self __renameTableToTemp:modelClass];
    BOOL ret2 = [self __createModelTableWithClassName:modelClass propertys:propertys];
    BOOL ret3 = [self __insertIntoNewTableFromTemp:modelClass];
    BOOL ret4 = [self __dropTempTable:modelClass];
    return ret0 && ret1 && ret2 && ret3 && ret4;
}

/**
 * 将table重命名为table_temp
 */
- (BOOL)__renameTableToTemp:(NSString *)modelClass {
    NSString *SQLite = [NSString stringWithFormat:@"ALTER TABLE %@ RENAME TO %@_temp;",modelClass,modelClass];
    BOOL result = [self __executeUpdateSQLite:SQLite arguments:nil];
    if (result) {
        [_storage.tables removeObject:modelClass];
        [_storage.tables addObject:[NSString stringWithFormat:@"%@_temp",modelClass]];
    }
    return result;
}

/**
 * 从table_temp赋值到新table
 */
- (BOOL)__insertIntoNewTableFromTemp:(NSString *)modelClass {
    NSString *SQLite = [NSString stringWithFormat:@"INSERT INTO %@ SELECT * FROM %@_temp;",modelClass,modelClass];
    return [self __executeUpdateSQLite:SQLite arguments:nil];
}

/**
 * 删除table_temp
 */
- (BOOL)__dropTempTable:(NSString *)modelClass {
    return [self dropTable:[NSString stringWithFormat:@"%@_temp",modelClass]];
}

@end
