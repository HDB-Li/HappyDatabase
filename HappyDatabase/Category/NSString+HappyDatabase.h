//
//  NSString+HappyDatabase.h
//  HappyDatabase
//
//  Created by Li on 2017/5/24.
//  Copyright © 2017年 Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HDBCountItem.h"

@interface NSString (HappyDatabase)

/**
 * 判断字符串是否存在
 */
- (BOOL)HDB_isExist;

/**
 * NSString转化成HDBCountItem
 */
- (HDBCountItem *)HDB_convertToCountItem;
@end
