// Copyright 2016 Sysdata Digital
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
