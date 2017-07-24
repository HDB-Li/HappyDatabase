//
//  HDBManager+Extra.h
//  HappyDatabase
//
//  Created by Li on 2017/7/19.
//  Copyright © 2017年 Li. All rights reserved.
//

#import "HDBManager.h"

#pragma mark - (Internal) 这部分接口用于内部使用,不建议调用
/**
 * 这部分接口用于内部使用,不建议调用.
 */
@interface HDBManager (Internal)

/**
 * 根据模型修改,更改字段名
 
 @param modelClass 模型的类名
 @param parameters 旧字段和新字段的字典,Key为旧字段,value为新字段
 */
- (BOOL)updateTable:(NSString *)modelClass parameters:(NSDictionary *)parameters;

@end

#pragma mark - (DefaultTable) 通用型表格式,包含模型数据、加入数据库时间和数据标识
/**
 * 这部分的接口用于创建一个默认的表(只包含模型Data和加入数据库的时间戳),通常用于不需采用条件查询和修改的情况,例如记录app使用过程中的定位点信息,页面/按钮的埋点事件,某些页面的Model数据缓存.
 */
@interface HDBManager (DefaultTable)

/**
 * 创建一个默认格式的表
 */
- (BOOL)registerDefaultTableWithName:(NSString *)tableName;

/**
 * 删除一个默认格式的表
 */
- (BOOL)dropDefaultTable:(NSString *)tableName;

/**
 * 插入一个Object
 
 @param object 遵循NSCoding
 @param identify 标识,用于查找/更新/删除。若只需要记录数据,不需要按条件查询,则传nil.例如埋点/log/一些运行信息
 @param tableName 表名
 */
- (BOOL)insertObject:(id<NSCoding>)object identify:(NSString *)identify table:(NSString *)tableName;

/**
 * 删除一个Object
 
 @param identify 标识,用于删除
 @param tableName 表名
 */
- (BOOL)deleteObjectWithIdentify:(NSString *)identify table:(NSString *)tableName;

/**
 * 修改一个Object数据,没有则添加一条数据
 
 @param object 遵循NSCoding
 @param identify 标识,用于查找/更新/删除
 @param tableName 表名
 */
- (BOOL)updateObject:(id<NSCoding>)object identify:(NSString *)identify table:(NSString *)tableName;

/**
 * 查询一个Object
 
 @param identify 标识,用于查找
 @param tableName 表名
 */
- (id)queryObjectWithIdentify:(NSString *)identify table:(NSString *)tableName;

/**
 * 查询表中所有的Object
 
 @param tableName 表名
 */
- (NSArray *)queryAllObjectsFromDefaultTable:(NSString *)tableName;

@end

#pragma mark - (Database) 多数据库处理
/**
 * 这部分的接口用于处理需要多个数据库的情况,通常情况下是不需要添加数据库的,因为HDBManager在初始化的时候会默认创建一个名字叫做"database"的数据库.
 */
@interface HDBManager (Database)

/**
 * 更改当前操作的数据库,如果不存在这个数据库,会自动创建并设为当前操作的数据库
 
 @param dbName 数据库名称
 */
- (BOOL)setUpDatabaseWithName:(NSString *)dbName;

#warning 这里应该把HDBVerControl也改成可以支持多数据库的.

@end
