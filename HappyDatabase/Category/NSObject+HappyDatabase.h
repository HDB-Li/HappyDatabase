//
//  NSObject+HappyDatabase.h
//  HappyDatabase
//
//  Created by Li on 2017/5/24.
//  Copyright © 2017年 Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (HappyDatabase)

/**
 * 获取一个类的所有属性名
 */
+ (NSMutableArray <NSString *>*)HDB_properties;

@end
