//
//  HDBManager.h
//  HappyDatabase
//
//  Created by Li on 2017/5/23.
//  Copyright © 2017年 Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HDBConditionInput.h"
#import "HDBConfig.h"
#import "HDBCondition.h"
#import "HDBConditionGroup.h"

@interface HDBManager : NSObject

#pragma mark - Initial

/**
 * 初始化方法
 */
+ (instancetype)sharedManager;

/**
 * 注册需要创建的模型,模型必须遵守并实现<NSCoding>协议.如果你实现了<NSCoding>协议,但是并没有声明协议,建议你在model.h中声明协议.
 * 注册成功后,会自动创建对应的表.
 * PrimaryKey不可以为空,并且primaryKey必须是模型的一个属性名称
 * AllowedKeys中填入需要存储的属性名称,必须包含primaryKey的属性名称
 * IgnoredKeys中填入需要忽略的属性名称,不可以包含primarykey的属性名称
 * AllowedKeys和ignoredKeys都为空时,默认注册模型所有属性名称;只有allowedKeys存在时,以allowedKeys为基准注册模型;只有ignoredKeys存在时,从所有属性中除去ignoredKeys,再注册模型;allowedKeys和ignoredKeys同时存在时,以allowedKeys有准.

 @param modelName 模型名称
 @param primaryKey 关键字段
 @param allowedKeys 需要属性集
 @param ignoredKeys 忽略属性集
 @return YES: 注册成功 NO: 注册失败
 */
- (BOOL)registerClass:(NSString *)modelName primaryKey:(NSString *)primaryKey allowedKeys:(NSArray *)allowedKeys ignoredKeys:(NSArray *)ignoredKeys;

#pragma mark - Insert

/**
 * 插入一个模型数据.
 
 @param model 需要存储的模型数据,需要遵守<NSCoding>协议 / The model need to store,need Conform Protocol <NSCoding>.
 */
- (BOOL)insertModel:(id<NSCoding>)model;

#pragma mark - Drop

/**
 * 删除一个模型数据.
 
 @param model 需要存储的模型数据,需要遵守<NSCoding>协议 / The model need to store,need Conform Protocol <NSCoding>.
 */
- (BOOL)deleteModel:(id<NSCoding>)model;

/**
 * 根据一个关键值去删除模型.

 @param modelClass 模型的类名
 @param primaryValue 模型的PrimaryKey对应的属性值
 */
- (BOOL)deleteModel:(NSString *)modelClass primaryValue:(id)primaryValue;

/**
 * 根据一个属性名/值字典去删除模型
 * 通过parameters的key/value来匹配, WHERE 'KEY' = VALUE,eg:如果想匹配一个age是10的对象,parameters应为:@{@"age":@"10"}
 
 @param modelClass 模型的类名
 @param parameters 用于匹配的字典,key为属性名,value为属性值
 */
- (BOOL)deleteModel:(NSString *)modelClass parameters:(NSDictionary *)parameters;

#pragma mark - Update

/**
 * 同步一个模型数据,没有则创建.
 * 模型中的PrimaryValue不可以改变,如果改变了PrimaryValue,需要调用updateModel:oriPrimaryValue:这个接口.
 
 @param model 需要存储的模型数据,需要遵守<NSCoding>协议
 */
- (BOOL)updateModel:(id<NSCoding>)model;

/**
 * 修改一个模型的PrimaryValue,同时同步所有关联关系.
 * 例如模型表中的PrimaryKey是"age",把一个模型的age从10改为11时,oriPrimaryValue则传入10.

 @param model 需要存储的模型数据,需要遵守<NSCoding>协议
 @param oriPrimaryValue 旧的关键值
 */
- (BOOL)updateModel:(id<NSCoding>)model oriPrimaryValue:(id)oriPrimaryValue;

#pragma mark - Query

/**
 * 查询表中所有的Object
 
 @param tableName 表名
 */
- (NSArray *)queryAllObjectsFromTable:(NSString *)tableName;

/**
 * 根据PrimaryValue查询一个模型,不存在则返回nil

 @param modelClass 模型的类名
 @param primaryValue 模型的PrimaryKey对应的属性值
 */
- (id)queryModel:(NSString *)modelClass primaryValue:(id)primaryValue;

/**
 * 查询一组符合条件的模型集合
 * 通过parameters的key/value来匹配, WHERE 'KEY' = VALUE,eg:如果想匹配一个age是10的对象,parameters应为:@{@"age":@"10"}
 
 @param modelClass 模型的类名
 @param parameters 用于匹配的字典,key为属性名,value为属性值
 */
- (NSArray *)queryModels:(NSString *)modelClass parameters:(NSDictionary *)parameters;

/**
 * 查询一组符合条件的模型集合
 * HDBCondition(用于单一约束条件) / HDBConditionGroup(用于多约束条件),具体请看HDBCondtion.h和HDBConditionGroup.h

 @param modelClass 模型的类名
 @param condition HDBCondition
 */
- (NSArray *)queryModels:(NSString *)modelClass HDBConditions:(id<HDBConditionInput>)condition;

/**
 * 根据SQLite语句查询一组符合条件的模型集合

 @param modelClass 模型的类名
 @param SQLite SQLite语句
 @param arguments 参数,不需要则传nil
 */
- (NSArray *)queryModels:(NSString *)modelClass SQLiteString:(NSString *)SQLite arguments:(NSArray *)arguments;

#pragma mark - Table Method

/**
 * 删除一个表
 */
- (BOOL)dropTable:(NSString *)tableName;

/**
 * 清除表中内所有数据
 */
- (BOOL)clearTable:(NSString *)tableName;

/**
 * 获取一个表内数据的数量
 */
- (NSUInteger)countFromTable:(NSString *)tableName;

/**
 * 获取当前Database中的所有表
 */
- (NSArray *)queryAllTableNamesInDB;

@end



