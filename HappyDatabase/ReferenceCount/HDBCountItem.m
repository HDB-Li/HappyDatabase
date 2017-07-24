//
//  HDBCountItem.m
//  HappyDatabase
//
//  Created by Li on 2017/5/24.
//  Copyright © 2017年 Li. All rights reserved.
//

#import "HDBCountItem.h"
#import "HDBDefined.h"

@interface HDBCountItem ()

@property (nonatomic, assign) BOOL isSelf;

/**
 0: Normal  1:Array 2:Dictionary
 */
@property (nonatomic, assign) NSInteger type;

@end

@implementation HDBCountItem

/**
 * 返回一个自身创建的引用计数
 */
+ (instancetype)SelfItem {
    HDBCountItem *item = [[HDBCountItem alloc] init];
    item.isSelf = YES;
    return item;
}

/**
 * 指定的类初始化方法
 */
+ (instancetype)itemWithParent:(NSString *)parent name:(NSString *)name parentKey:(NSString *)parentKey {
    return [[self alloc] initWithParent:parent name:name parentKey:parentKey];
}

/**
 * 指定的类初始化方法
 */
+ (instancetype)itemWithParent:(NSString *)parent name:(NSString *)name parentKey:(NSString *)parentKey arrayIndex:(NSInteger)index {
    return [[self alloc] initWithParent:parent name:name parentKey:parentKey arrayIndex:index];
}

/**
 * 指定的类初始化方法
 */
+ (instancetype)itemWithParent:(NSString *)parent name:(NSString *)name parentKey:(NSString *)parentKey dictionaryKey:(NSString *)key {
    return [[self alloc] initWithParent:parent name:name parentKey:parentKey dictionaryKey:key];
}

/**
 * 指定的初始化方法
 */
- (instancetype)initWithParent:(NSString *)parent name:(NSString *)name parentKey:(NSString *)parentKey {
    if (self = [super init]) {
        _parent = parent;
        _name = name;
        _parentKey = parentKey;
    }
    return self;
}

/**
 * 指定的初始化方法
 */
- (instancetype)initWithParent:(NSString *)parent name:(NSString *)name parentKey:(NSString *)parentKey arrayIndex:(NSInteger)index {
    if (self = [super init]) {
        _parent = parent;
        _name = name;
        _parentKey = parentKey;
        _locationKey = @(index).stringValue;
        _type = 1;
    }
    return self;
}

/**
 * 指定的初始化方法
 */
- (instancetype)initWithParent:(NSString *)parent name:(NSString *)name parentKey:(NSString *)parentKey dictionaryKey:(NSString *)key {
    if (self = [super init]) {
        _parent = parent;
        _name = name;
        _parentKey = parentKey;
        _locationKey = key;
        _type = 2;
    }
    return self;
}

/**
 * HDBCountItem转化成NSString
 */
- (NSString *)countItemString {
    if (_isSelf) {
        return HDB_kOwnerSelf;
    } else if (_type == 1) {
        return [NSString stringWithFormat:@"%@:%@:%@:%@-%@",_parent,_name,_parentKey,@"A",_locationKey];
    } else if (_type == 2) {
        return [NSString stringWithFormat:@"%@:%@:%@:%@-%@",_parent,_name,_parentKey,@"D",_locationKey];
    }
    return [NSString stringWithFormat:@"%@:%@:%@",_parent,_name,_parentKey];
}
@end
