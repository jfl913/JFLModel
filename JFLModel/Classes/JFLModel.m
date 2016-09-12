//
//  JFLModel.m
//  Pods
//
//  Created by LiJunfeng on 16/9/10.
//
//

#import "JFLModel.h"
#import <objc/runtime.h>
#import "EXTScope.h"

static void *JFLModelCachedPropertyKeysKey = &JFLModelCachedPropertyKeysKey;

@implementation JFLModel

#pragma mark Reflection

+ (void)enumeratePropertiesUsingBlock:(void (^)(objc_property_t property, BOOL *stop))block
{
    Class cls = self;
    BOOL stop = NO;
    
    while (!stop) {
        unsigned count = 0;
        objc_property_t *properties = class_copyPropertyList(cls, &count);
        
        cls = cls.superclass;
        if (properties == NULL) continue;
        
        
    }
}

+ (NSSet *)propertyKeys
{
    NSSet *cachedKeys = objc_getAssociatedObject(self, JFLModelCachedPropertyKeysKey);
    if (cachedKeys != nil) return cachedKeys;
    
    NSMutableSet *keys = [NSMutableSet set];
    
    
    objc_setAssociatedObject(self, JFLModelCachedPropertyKeysKey, keys, OBJC_ASSOCIATION_COPY);
    
    return keys;
}


@end
