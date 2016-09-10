//
//  JFLJSONAdapter.m
//  Pods
//
//  Created by LiJunfeng on 16/9/10.
//
//

#import "JFLJSONAdapter.h"

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
    
    return self;
}

@end
