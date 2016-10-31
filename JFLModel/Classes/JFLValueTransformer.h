//
//  JFLValueTransformer.h
//  Pods
//
//  Created by LiJunfeng on 2016/10/25.
//
//

#import <Foundation/Foundation.h>

// TODO: 为什么success和error这样写？
typedef id(^JFLValueTransformerBlock)(id value, BOOL *success, NSError **error);

@interface JFLValueTransformer : NSValueTransformer

//+ (instancetype)

@end
