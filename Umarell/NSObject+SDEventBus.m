//
//  NSObject+SDEventBus.m
//  PublishSubscribe
//
//  Created by Francesco Ceravolo on 18/05/16.
//  Copyright © 2016 Sysdata Digital. All rights reserved.
//

#import "NSObject+SDEventBus.h"
#import <objc/runtime.h> // very important to import this!

@implementation NSObject (SDEventBus)

+ (NSSet*) keyPathsForValuesAffectingObservableSelf
{
    NSSet* keyPaths = [NSSet new];
    NSMutableArray* keys = [NSMutableArray array];
    unsigned int count;
    objc_property_t* properties = class_copyPropertyList([self class], &count);  // see imports above!
    
    for (size_t i = 0; i < count; ++i)
    {
        NSString* property = [NSString stringWithCString:property_getName(properties[i])
                                                encoding:NSASCIIStringEncoding];
        
        if ([property isEqualToString:EVENTBUS_OBSERV_ALL_PROPERTIES_KEYS] == NO)
        {
            [keys addObject:property];
        }
    }
    free(properties);
    
    keyPaths = [keyPaths setByAddingObjectsFromArray:keys];
    
    return keyPaths;
}

- (void) setObservableSelf:(NSInteger)observableSelf
{
}

- (NSInteger) observableSelf
{
    return 0;
}

@end
