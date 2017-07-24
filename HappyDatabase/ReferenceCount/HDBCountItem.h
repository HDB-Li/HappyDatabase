//
//  HDBCountItem.h
//  HappyDatabase
//
//  Created by Li on 2017/5/24.
//  Copyright © 2017年 Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HDBCountItem : NSObject

/**
 * 父类,具体是哪一个模型(table)创建的这个引用计数
 */
@property (nonatomic, copy, readonly) NSString *parent;

/**
 * 属性名,具体是哪一个父类的属性创建的这个引用计数
 */
@property (nonatomic, copy, readonly) NSString *name;

/**
 * 父类的PrimaryKey,用去在父类的表中查询到父类信息
 */
@property (nonatomic, copy, readonly) NSString *parentKey;

/**
 * 关键字,如果是有数组/字典创建的引用计数,locationKey记录数组的序号或字典的key.默认是nil
 */
@property (nonatomic, copy, readonly) NSString *locationKey;

/**
 * 区分是父类引用还是自身创建,YES:自身创建 NO:父类引用
 */
@property (nonatomic, assign, readonly) BOOL isSelf;

/**
 * 模型对应的引用计数字符串
 */
@property (nonatomic, copy , readonly) NSString *countItemString;


/**
 * 返回一个自身创建的引用计数
 */
+ (instancetype)SelfItem;

/**
 * 返回一个由父类创建的引用计数
 */

/**
 * 返回一个由父类创建的引用计数

 * parent 详见parent属性
 * name 详见name属性
 * parentKey 详见parentKey属性
 * arrayIndex 如果是数组中的模型,此处传入模型在数组中的下标
 * dictionaryKey 如果是字典中的模型,此处传入模型在字典中对应的Key
 */
+ (instancetype)itemWithParent:(NSString *)parent name:(NSString *)name parentKey:(NSString *)parentKey;
+ (instancetype)itemWithParent:(NSString *)parent name:(NSString *)name parentKey:(NSString *)parentKey arrayIndex:(NSInteger)index;
+ (instancetype)itemWithParent:(NSString *)parent name:(NSString *)name parentKey:(NSString *)parentKey dictionaryKey:(NSString *)key;

@end
