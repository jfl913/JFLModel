//
//  JFLValueTransformer.m
//  Pods
//
//  Created by LiJunfeng on 2016/10/25.
//
//

#import "JFLValueTransformer.h"

@interface JFLReversibleValueTransformer : JFLValueTransformer
@end

@interface JFLValueTransformer ()

@property (nonatomic, copy, readonly) JFLValueTransformerBlock forwardBlock;
@property (nonatomic, copy, readonly) JFLValueTransformerBlock reverseBlock;

@end

@implementation JFLValueTransformer

#pragma mark Liftcycle

+ (instancetype)transformerUsingForwardBlock:(JFLValueTransformerBlock)forwardBlock
{
    return [[self alloc] initWithForwardBlock:forwardBlock reverseBlock:nil];
}

+ (instancetype)transformerUsingReversibleBlock:(JFLValueTransformerBlock)reversibleBlock
{
    return [self transformerUsingForwardBlock:reversibleBlock reverseBlock:reversibleBlock];
}

+ (instancetype)transformerUsingForwardBlock:(JFLValueTransformerBlock)forwardBlock reverseBlock:(JFLValueTransformerBlock)reverseBlock
{
    return [[JFLReversibleValueTransformer alloc] initWithForwardBlock:forwardBlock reverseBlock:reverseBlock];
}

- (id)initWithForwardBlock:(JFLValueTransformerBlock)forwardBlock reverseBlock:(JFLValueTransformerBlock)reverseBlock
{
    NSParameterAssert(forwardBlock != nil);
    
    self = [super init];
    if (self == nil) return nil;
    
    _forwardBlock = [forwardBlock copy];
    _reverseBlock = [reverseBlock copy];
    
    return self;
}

#pragma mark NSValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

+ (Class)transformedValueClass
{
    return [NSObject class];
}

- (id)transformedValue:(id)value
{
    NSError *error = nil;
    BOOL success = YES;
    
    return self.forwardBlock(value, &success, &error);
}

- (id)transformedValue:(id)value success:(BOOL *)outerSuccess error:(NSError *__autoreleasing *)outerError
{
    NSError *error = nil;
    BOOL success = YES;
    
    id transformedValue = self.forwardBlock(value, &success, &error);
    
    if (outerSuccess != NULL) *outerSuccess = success;
    if (outerError != NULL) *outerError = error;
    
    return transformedValue;
}

@end

@implementation JFLReversibleValueTransformer

#pragma mark Liftcycle

- (id)initWithForwardBlock:(JFLValueTransformerBlock)forwardBlock reverseBlock:(JFLValueTransformerBlock)reverseBlock
{
    NSParameterAssert(reverseBlock != nil);
    return [super initWithForwardBlock:forwardBlock reverseBlock:reverseBlock];
}

#pragma mark NSValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)reverseTransformedValue:(id)value
{
    NSError *error = nil;
    BOOL success = YES;
    
    return self.reverseBlock(value, &success, &error);
}

- (id)reverseTransformedValue:(id)value success:(BOOL *)outerSuccess error:(NSError *__autoreleasing *)outerError
{
    NSError *error = nil;
    BOOL success = YES;
    
    id transformedValue = self.reverseBlock(value, &success, &error);
    
    if (outerSuccess != NULL) *outerSuccess = success;
    if (outerError != NULL) *outerError = error;
    
    return transformedValue;
}

@end
