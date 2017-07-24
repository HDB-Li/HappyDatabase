//
//  NSObject+HappyDatabase.m
//  HappyDatabase
//
//  Created by Li on 2017/5/24.
//  Copyright © 2017年 Li. All rights reserved.
//

#import "NSObject+HappyDatabase.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <CoreData/CoreData.h>

static const char CachedPropertiesKey = '\0';

@implementation NSObject (HappyDatabase)

static NSMutableDictionary *cachedPropertiesDict_;

+ (void)load
{
    cachedPropertiesDict_ = [NSMutableDictionary dictionary];
}

+ (NSMutableDictionary *)dictForKey:(const void *)key
{
    @synchronized (self) {
        if (key == &CachedPropertiesKey) return cachedPropertiesDict_;
        return nil;
    }
}

+ (NSMutableArray <NSString *>*)HDB_properties; {
    
    NSMutableArray *cachedProperties = [self dictForKey:&CachedPropertiesKey][NSStringFromClass(self)];
    
    if (cachedProperties == nil) {
        cachedProperties = [[NSMutableArray alloc] init];
        
        Class c = self;
        
        while (c && [self isIgnoreClass:c] == NO) {
            unsigned int count = 0;
            
            objc_property_t *properties = class_copyPropertyList(c, &count);
            
            for (unsigned int i = 0; i < count; i++) {
                NSString *name = [self cachedPropertyWithProperty:properties[i]];
                if (name) {
                    [cachedProperties addObject:name];
                }
            }
            
            free(properties);
            
            c = [c superclass];
        }
        
        [self dictForKey:&CachedPropertiesKey][NSStringFromClass(self)] = cachedProperties;
    }
    
    return cachedProperties;
    
}

+ (NSString *)cachedPropertyWithProperty:(objc_property_t)property {
    NSString *name = objc_getAssociatedObject(self, property);
    if (name == nil) {
        name = @(property_getName(property));
        objc_setAssociatedObject(self, property, name, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return name;
}

+ (BOOL)isIgnoreClass:(Class)class {
    
    if (class == [NSObject class] || class == [NSManagedObject class]) return YES;
    
    static NSSet *ignoreSet;
    if (ignoreSet == nil) {
        ignoreSet = [NSSet setWithObjects:
                     [NSURL class],
                     [NSDate class],
                     [NSValue class],
                     [NSData class],
                     [NSError class],
                     [NSArray class],
                     [NSDictionary class],
                     [NSString class],
                     [NSAttributedString class],
                     [UIResponder class],nil];
    }
    
    __block BOOL result = NO;
    [ignoreSet enumerateObjectsUsingBlock:^(Class ignoreClass, BOOL *stop) {
        if ([class isSubclassOfClass:ignoreClass]) {
            result = YES;
            *stop = YES;
        }
    }];
    return result;
}

@end
