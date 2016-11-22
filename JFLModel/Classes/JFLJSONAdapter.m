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
#import "JFLValueTransformer.h"
#import "NSDictionary+JFLJSONKeyPath.h"

NSString * const JFLJSONAdapterErrorDomain = @"JFLJSONAdapterErrorDomain";
const NSInteger JFLJSONAdapterErrorInvalidJSONDictionary = 3;

@interface JFLJSONAdapter ()

@property (nonatomic, strong, readonly) Class modelClass;
@property (nonatomic, copy, readonly) NSDictionary *JSONKeyPathsByPropertyKey;
@property (nonatomic, copy) NSDictionary *valueTransformersByPropertyKey;

@end

@implementation JFLJSONAdapter

#pragma mark - Convenience methods

+ (id)modelOfClass:(Class)modelClass
         fromModel:(id)model
             error:(NSError **)error
{
    NSDictionary *JSONDictionary = [self JSONDictionaryFromModel:model
                                                           error:error];
    return [self modelOfClass:modelClass
           fromJSONDictionary:JSONDictionary
                        error:error];
}

+ (NSDictionary *)JSONDictionaryFromModel:(id<JFLJSONSerializing>)model
                                    error:(NSError **)error
{
    JFLJSONAdapter *adapter = [[self alloc] initWithModelClass:model.class];
    return [adapter JSONDictionaryFromModel:model error:error];
}

+ (id)modelOfClass:(Class)modelClass
fromJSONDictionary:(NSDictionary *)JSONDictionary
             error:(NSError **)error
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

// 把model转化为字典
- (NSDictionary *)JSONDictionaryFromModel:(id<JFLJSONSerializing>)model error:(NSError **)error
{
    NSParameterAssert(model != nil);
    NSParameterAssert([model isKindOfClass:self.modelClass]);
    
    if (self.modelClass != model.class) {
        // 暂时不写
    }
    
    NSSet *propertyKeysToSerialize = [self serializablePropertyKeys:[NSSet setWithArray:self.JSONKeyPathsByPropertyKey.allKeys] forModel:model];
    
    NSDictionary *dictionaryValue = [model.dictionaryValue dictionaryWithValuesForKeys:propertyKeysToSerialize.allObjects];
    NSMutableDictionary *JSONDictionary = [[NSMutableDictionary alloc] initWithCapacity:dictionaryValue.count];
    
    __block BOOL success = YES;
    __block NSError *tmpError = nil;
    
    [dictionaryValue enumerateKeysAndObjectsUsingBlock:^(NSString *propertyKey, id value, BOOL *stop) {
        id JSONKeyPaths = self.JSONKeyPathsByPropertyKey[propertyKey];
        
        if (JSONKeyPaths == nil) return;
        
        NSValueTransformer *transformer = self.valueTransformersByPropertyKey[propertyKey];
        if ([transformer.class allowsReverseTransformation]) {
            if ([value isEqual:NSNull.null]) value = nil;
            
            if ([transformer respondsToSelector:@selector(reverseTransformedValue:success:error:)]) {
                id<JFLTransformerErrorHandling> errorHandlingTransformer = (id)transformer;
                
                value = [errorHandlingTransformer reverseTransformedValue:value success:&success error:&tmpError];
                
                if (!success) {
                    *stop = YES;
                    return;
                }
            } else {
                value = [transformer reverseTransformedValue:value] ?: NSNull.null;
            }
        }
        
        void (^createComponents)(id, NSString *) = ^(id obj, NSString *keyPath) {
            NSArray *keyPathComponents = [keyPath componentsSeparatedByString:@"."];
            
            for (NSString *component in keyPathComponents) {
                if ([obj valueForKey:component] == nil) {
                    [obj setValue:[NSMutableDictionary dictionary] forKey:component];
                }
                
                obj = [obj valueForKey:component];
            }
        };
        
        if ([JSONKeyPaths isKindOfClass:[NSString class]]) {
            createComponents(JSONDictionary, JSONKeyPaths);
            
            [JSONDictionary setValue:value forKeyPath:JSONKeyPaths];
        }
        
        if ([JSONKeyPaths isKindOfClass:[NSArray class]]) {
            for (NSString *JSONKeyPath in JSONKeyPaths) {
                createComponents(JSONDictionary, JSONKeyPath);
                
                [JSONDictionary setValue:value forKeyPath:JSONKeyPath];
            }
        }
    }];
    
    if (success) {
        return JSONDictionary;
    } else {
        if (error != NULL) *error = tmpError;
        
        return nil;
    }
}

- (id)modelFromJSONDictionary:(NSDictionary *)JSONDictionary error:(NSError **)error
{
    // 类簇暂不处理
    
    NSMutableDictionary *dictionaryValue = [[NSMutableDictionary alloc] initWithCapacity:JSONDictionary.count];
    // 这里把服务端给过来的字典，key都替换为model里面的property，value转换为我们需要的类型。存到dictionaryValue。
    for (NSString *propertyKey in [self.modelClass propertyKeys]) {
        id JSONKeyPaths = self.JSONKeyPathsByPropertyKey[propertyKey];
        
        if (JSONKeyPaths == nil) continue;
        
        id value;
        
        if ([JSONKeyPaths isKindOfClass:[NSArray class]]) {
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            
            for (NSString *keyPath in JSONKeyPaths) {
                BOOL success = NO;
                id value = [JSONDictionary jfl_valueForJSONKeyPath:keyPath success:&success error:error];
                
                if (!success) return nil;
                
                if (value != nil) dictionary[keyPath] = value;
            }
            
            value = dictionary;
        } else {
            BOOL success = NO;
            value = [JSONDictionary jfl_valueForJSONKeyPath:JSONKeyPaths success:&success error:error];
            
            if (!success) return nil;
        }
        
        if (value == nil) continue;
        
        @try {
            NSValueTransformer *transformer = self.valueTransformersByPropertyKey[propertyKey];
            if (transformer != nil) {
                if ([value isEqual:NSNull.null]) value = nil;
                
                if ([transformer respondsToSelector:@selector(transformedValue:success:error:)]) {
                    id<JFLTransformerErrorHandling> errorHandlingTransformer = (id)transformer;
                    
                    BOOL success = YES;
                    value = [errorHandlingTransformer transformedValue:value success:&success error:error];
                    
                    if (!success) return nil;
                } else {
                    value = [transformer transformedValue:value];
                }
                
                if (value == nil) value = NSNull.null;
            }
            
            dictionaryValue[propertyKey] = value;
        } @catch (NSException *exception) {
            
        } @finally {
            
        }
    }
    
    id model = [self.modelClass modelWithDictionary:dictionaryValue error:error];
    
    return [model validate:error] ? model : nil;
}

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

- (NSSet *)serializablePropertyKeys:(NSSet *)propertyKeys forModel:(id <JFLJSONSerializing>)model
{
    return propertyKeys;
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
    
    return [JFLValueTransformer transformerUsingForwardBlock:^id(id JSONDictionary, BOOL *success, NSError *__autoreleasing *error) {
        if (JSONDictionary == nil) return nil;
        
        if (![JSONDictionary isKindOfClass:[NSDictionary class]]) {
            if (error != NULL) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: @"Could not convert JSON dictionary to model object",
                                           NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"Expected an NSDictionary, got: %@", JSONDictionary],
                                           JFLTransformerErrorHandlingInputValueErrorKey: JSONDictionary
                                           };
                *error = [NSError errorWithDomain:JFLTransformerErrorHandlingErrorDomain code:JFLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
                
            }
            
            *success = NO;
            return nil;
        }
        
        if (!adapter) {
            adapter = [[self alloc] initWithModelClass:modelClass];
        }
        id model = [adapter modelFromJSONDictionary:JSONDictionary error:error];
        if (model == nil) {
            *success = NO;
        }
        
        return model;
    } reverseBlock:^ NSDictionary * (id model, BOOL *success, NSError *__autoreleasing *error) {
        if (model == nil) return nil;
        
        if (![model conformsToProtocol:@protocol(JFLModel)] || ![model conformsToProtocol:@protocol(JFLJSONSerializing)]) {
            if (error != NULL) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: @"Could not convert model object to JSON dictionary",
                                           NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"Expected a JFLModel object conforming to <JFLJSONSerializing>, got: %@", model],
                                           JFLTransformerErrorHandlingInputValueErrorKey: model
                                           };
                *error = [NSError errorWithDomain:JFLTransformerErrorHandlingErrorDomain code:JFLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
            }
            *success = NO;
            return nil;
        }
        
        if (!adapter) {
            adapter = [[self alloc] initWithModelClass:modelClass];
        }
        NSDictionary *result = [adapter JSONDictionaryFromModel:model error:error];
        if (result == nil) {
            *success = NO;
        }
        
        return result;
    }];
    
}

@end
