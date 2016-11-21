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
#import "JFLRuntimeExtensions.h"

static void *JFLModelCachedPropertyKeysKey = &JFLModelCachedPropertyKeysKey;
static void *JFLModelCachedTransitoryPropertyKeysKey = &JFLModelCachedTransitoryPropertyKeysKey;
static void *JFLModelCachedPermanentPropertyKeysKey = &JFLModelCachedPermanentPropertyKeysKey;

@implementation JFLModel

#pragma mark Lifecycle

+ (void)generateAndCacheStorageBehaviors
{
    NSMutableSet *transitoryKeys = [NSMutableSet set];
    NSMutableSet *permanentKeys = [NSMutableSet set];
    
    for (NSString *propertyKey in self.propertyKeys) {
        switch ([self storageBehaviorForPropertyWithKey:propertyKey]) {
            case JFLPropertyStorageNone:
                break;
            case JFLPropertyStorageTransitory:
                [transitoryKeys addObject:propertyKey];
                break;
            case JFLPropertyStoragePermanent:
                [permanentKeys addObject:propertyKey];
                break;
            default:
                break;
        }
    }
    
    objc_setAssociatedObject(self, JFLModelCachedTransitoryPropertyKeysKey, transitoryKeys, OBJC_ASSOCIATION_COPY);
    objc_setAssociatedObject(self, JFLModelCachedPermanentPropertyKeysKey, permanentKeys, OBJC_ASSOCIATION_COPY);
}

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary error:(NSError **)error
{
//    return [[self alloc] initWithDictionary:<#(nonnull NSDictionary *)#>]
}

- (instancetype)init
{
    return [super init];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary error:(NSError **)error
{
    self = [self init];
    if (self == nil) return nil;
    
    
}

#pragma mark Reflection

+ (void)enumeratePropertiesUsingBlock:(void (^)(objc_property_t property, BOOL *stop))block
{
    Class cls = self;
    BOOL stop = NO;
    
    while (!stop && ![cls isEqual:JFLModel.class]) {
        unsigned count = 0;
        objc_property_t *properties = class_copyPropertyList(cls, &count);
        
        cls = cls.superclass;
        if (properties == NULL) continue;
        
        // 退出时，释放properties
        // for automatically cleaning up manually-allocated memory, file handles, locks, etc., at the end of a scope.
        @onExit {
            free(properties);
        };
        
        for (unsigned i = 0; i < count; i++) {
            block(properties[i], &stop);
            if (stop) break;
        }
    }
}

+ (NSSet *)propertyKeys
{
    NSSet *cachedKeys = objc_getAssociatedObject(self, JFLModelCachedPropertyKeysKey);
    if (cachedKeys != nil) return cachedKeys;
    
    NSMutableSet *keys = [NSMutableSet set];
    
    [self enumeratePropertiesUsingBlock:^(objc_property_t property, BOOL *stop) {
        NSString *key = @(property_getName(property));
        
        if ([self storageBehaviorForPropertyWithKey:key] != JFLPropertyStorageNone) {
            [keys addObject:key];
        }
    }];
    
    objc_setAssociatedObject(self, JFLModelCachedPropertyKeysKey, keys, OBJC_ASSOCIATION_COPY);
    
    return keys;
}

+ (NSSet *)transitoryPropertyKeys
{
    NSSet *transitoryPropertyKeys = objc_getAssociatedObject(self, JFLModelCachedTransitoryPropertyKeysKey);
    
    if (transitoryPropertyKeys == nil) {
        [self generateAndCacheStorageBehaviors];
        transitoryPropertyKeys = objc_getAssociatedObject(self, JFLModelCachedTransitoryPropertyKeysKey);
    }
    
    return transitoryPropertyKeys;
}

+ (NSSet *)permanentPropertyKeys
{
    NSSet *permanentPropertyKeys = objc_getAssociatedObject(self, JFLModelCachedPermanentPropertyKeysKey);
    
    if (permanentPropertyKeys == nil) {
        [self generateAndCacheStorageBehaviors];
        permanentPropertyKeys = objc_getAssociatedObject(self, JFLModelCachedPermanentPropertyKeysKey);
    }
    
    return permanentPropertyKeys;
}

- (NSDictionary *)dictionaryValue
{
    NSSet *keys = [self.class.transitoryPropertyKeys setByAddingObjectsFromSet:self.class.permanentPropertyKeys];
    
    return [self dictionaryWithValuesForKeys:keys.allObjects];
}

+ (JFLPropertyStorage)storageBehaviorForPropertyWithKey:(NSString *)propertyKey
{
    objc_property_t property = class_getProperty(self.class, propertyKey.UTF8String);
    
    if (property == NULL) return JFLPropertyStorageNone;
    
    jfl_propertyAttributes *attributes = jfl_copyPropertyAttributes(property);
    @onExit {
        free(attributes);
    };
    
    BOOL hasGetter = [self instancesRespondToSelector:attributes->getter];
    BOOL hasSetter = [self instancesRespondToSelector:attributes->setter];
    if (!attributes->dynamic && attributes->ivar == NULL && !hasGetter && !hasSetter) {
        return JFLPropertyStorageNone;
    } else if (attributes->readonly && attributes->ivar == NULL) {
        if ([self isEqual:JFLModel.class]) {
            return JFLPropertyStorageNone;
        } else {
            // Check superclass in case the subclass redeclares a property that falls through
            return [self.superclass storageBehaviorForPropertyWithKey:propertyKey];
        }
    } else {
        return JFLPropertyStoragePermanent;
    }
}


@end
