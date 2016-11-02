//
//  JFLValueTransformer.h
//  Pods
//
//  Created by LiJunfeng on 2016/10/25.
//
//

#import <Foundation/Foundation.h>
#import "JFLTransformerErrorHandling.h"

// TODO: 为什么success和error这样写？
typedef id(^JFLValueTransformerBlock)(id value, BOOL *success, NSError **error);

@interface JFLValueTransformer : NSValueTransformer <JFLTransformerErrorHandling>

+ (instancetype)transformerUsingForwardBlock:(JFLValueTransformerBlock)transformation;

+ (instancetype)transformerUsingReversibleBlock:(JFLValueTransformerBlock)transformation;

+ (instancetype)transformerUsingForwardBlock:(JFLValueTransformerBlock)forwardTransformation reverseBlock:(JFLValueTransformerBlock)reverseTransformation;

@end
