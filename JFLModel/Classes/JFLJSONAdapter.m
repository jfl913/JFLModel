//
//  JFLJSONAdapter.m
//  Pods
//
//  Created by LiJunfeng on 16/9/10.
//
//

#import "JFLJSONAdapter.h"
#import "JFLModel.h"

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
        
    }
    
    
    return nil;
}

@end
