//
//  JFLJSONAdapter.m
//  Pods
//
//  Created by LiJunfeng on 16/9/10.
//
//

#import <objc/runtime.h>
#import "JFLRuntimeExtensions.h"
#import "EXTScope.h"

#import "JFLJSONAdapter.h"
#import "JFLModel.h"
#import "JFLReflection.h"
#import "JFLTransformerErrorHandling.h"

@interface JFLJSONAdapter ()

@property (nonatomic, strong, readonly) Class modelClass;
@property (nonatomic, copy, readonly) NSDictionary *JSONKeyPathsByPropertyKey;
@property (nonatomic, copy) NSDictionary *valueTransformersByPropertyKey;

@end

@implementation JFLJSONAdapter

#pragma mark - Convenience methods

+ (id)modelOfClass:(Class)modelClass
         fromModel:(id)model
             error:(NSError *)error
{
    NSDictionary *JSONDictionary = [self JSONDictionaryFromModel:model
                                                           error:error];
    return [self modelOfClass:modelClass
           fromJSONDictionary:JSONDictionary
                        error:error];
}

+ (NSDictionary *)JSONDictionaryFromModel:(id<JFLJSONSerializing>)model
                                    error:(NSError *)error
{
    JFLJSONAdapter *adapter = [[self alloc] initWithModelClass:model.class];
    return @{};
}

+ (id)modelOfClass:(Class)modelClass
fromJSONDictionary:(NSDictionary *)JSONDictionary
             error:(NSError *)error
{
    JFLJSONAdapter *adapter = [[self alloc] initWithModelClass:modelClass];
    return nil;
}

#pragma mark - Lifecycle

- (id)initWithModelClass:(Class)modelClass
{
    NSParameterAssert(modelClass != nil);
    NSParameterAssert([modelClass conformsToProtocol:@protocol(JFLJSONSerializing)]);
    
    self = [super init];
    if (self == nil) return nil;
    
    _modelClass = modelClass;
    
    _JSONKeyPathsByPropertyKey = [modelClass JSONKeyPathsByPropertyKey];
    
    NSSet *propertyKeys = [self.modelClass propertyKeys];
    
    for (NSString *mappedPropertyKey in _JSONKeyPathsByPropertyKey) {
        // 验证_JSONKeyPathsByPropertyKey里面的model的property在_modelClass中
        if (![propertyKeys containsObject:mappedPropertyKey]) {
            NSAssert(NO, @"%@ is not a property of %@.", mappedPropertyKey, modelClass);
            return nil;
        }
        
        // 验证JSON的key是否合法
        id value = _JSONKeyPathsByPropertyKey[mappedPropertyKey];
        
        if ([value isKindOfClass:[NSArray class]]) {
            for (NSString *keyPath in value) {
                if ([keyPath isKindOfClass:[NSString class]]) continue;
                
                NSAssert(NO, @"%@ must either map to a JSON key path or a JSON array of key paths, got: %@", mappedPropertyKey, value);
                return nil;
            }
        } else if (![value isKindOfClass:[NSString class]]) {
            NSAssert(NO, @"%@ must either map to a JSON key path or a JSON array of key paths, got: %@", mappedPropertyKey, value);
            return nil;
        }
    }
    
    _valueTransformersByPropertyKey = [self.class valueTransformersForModelClass:modelClass];
    
    return self;
}

#pragma mark - Serialization

+ (NSDictionary *)valueTransformersForModelClass:(Class)modelClass
{
    NSParameterAssert(modelClass != nil);
    NSParameterAssert([modelClass conformsToProtocol:@protocol(JFLJSONSerializing)]);
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    for (NSString *key in [modelClass propertyKeys]) {
        SEL selector = JFLSelectorWithKeyPattern(key, "JSONTransformer");
        if ([modelClass respondsToSelector:selector]) {
            IMP imp = [modelClass methodForSelector:selector];
            NSValueTransformer * (*function)(id, SEL) = (__typeof__(function))imp;
            NSValueTransformer *transformer = function(modelClass, selector);
            
            if (transformer != nil) result[key] = transformer;
            
            continue;
        }
        
        if ([modelClass respondsToSelector:@selector(JSONTransformerForKey:)]) {
            NSValueTransformer *transformer = [modelClass JSONTransformerForKey:key];
            
            if (transformer != nil) {
                result[key] = transformer;
                continue;
            }
        }
        
        objc_property_t property = class_getProperty(modelClass, key.UTF8String);
        
        if(property == NULL) continue;
        
        jfl_propertyAttributes *attributes = jfl_copyPropertyAttributes(property);
        @onExit {
            free(attributes);
        };
        
        NSValueTransformer *transformer = nil;
        
        if (*(attributes->type) == *(@encode(id))) {
            Class propertyClass = attributes->objectClass;
            
            if (propertyClass != nil) {
                transformer = [self transformerForModelPropertiesOfClass:modelClass];
            }
            
            // For user-defined JFLModel, try parse it with dictionaryTransformer.
            if (nil == transformer && [propertyClass conformsToProtocol:@protocol(JFLJSONSerializing)]) {
                
            }
        }
    }
    
    
    return nil;
}

+ (NSValueTransformer *)transformerForModelPropertiesOfClass:(Class)modelClass
{
    NSParameterAssert(modelClass != nil);
    
    SEL selector = JFLSelectorWithKeyPattern(NSStringFromClass(modelClass), "JSONTransformer");
    if (![self respondsToSelector:selector]) return nil;
    
    IMP imp  = [self methodForSelector:selector];
    NSValueTransformer * (*function)(id, SEL) = (__typeof__(function))imp;
    NSValueTransformer *result = function(self, selector);
    
    return result;
}

@end

@implementation JFLJSONAdapter (ValueTransformers)

+ (NSValueTransformer<JFLTransformerErrorHandling> *)dictionaryTransformerWithModelClass:(Class)modelClass
{
    NSParameterAssert([modelClass conformsToProtocol:@protocol(JFLModel)]);
    NSParameterAssert([modelClass conformsToProtocol:@protocol(JFLJSONSerializing)]);
    __block JFLJSONAdapter *adapter;
    
    
}

@end
