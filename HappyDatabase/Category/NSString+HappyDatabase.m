//
//  NSString+HappyDatabase.m
//  HappyDatabase
//
//  Created by Li on 2017/5/24.
//  Copyright © 2017年 Li. All rights reserved.
//

#import "NSString+HappyDatabase.h"
#import "HDBDefined.h"

@implementation NSString (HappyDatabase)

- (BOOL)HDB_isExist {
    if (!self) {
        return NO;
    }
    
    if (![self isKindOfClass:[NSString class]]) {
        return NO;
    }

    if ([self isEqualToString:@""] || self.length == 0) {
        return NO;
    }
    
    return YES;
}

- (HDBCountItem *)HDB_convertToCountItem {

    if ([self isEqualToString:HDB_kOwnerSelf]) {
        return [HDBCountItem SelfItem];
    }

    NSArray *array    = [self componentsSeparatedByString:@":"];
    if (array.count == 3) {
        return [HDBCountItem itemWithParent:[array firstObject] name:array[1] parentKey:[array lastObject]];
    }
    if (array.count == 4) {
        NSString *lastString = [array lastObject];
        NSArray *subArray = [lastString componentsSeparatedByString:@"-"];
        if (subArray.count == 2) {
            NSString *type = [subArray firstObject];
            NSString *indexOrKey = [subArray lastObject];
            if ([type isEqualToString:@"A"]) {
                return [HDBCountItem itemWithParent:[array firstObject] name:array[1] parentKey:array[2] arrayIndex:indexOrKey.integerValue];
            }
            return [HDBCountItem itemWithParent:[array firstObject] name:array[1] parentKey:array[2] dictionaryKey:indexOrKey];
        }
    }
    return nil;
}

@end
