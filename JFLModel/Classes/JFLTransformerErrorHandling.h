//
//  JFLTransformerErrorHandling.h
//  Pods
//
//  Created by LiJunfeng on 2016/10/25.
//
//

#import <Foundation/Foundation.h>

extern NSString * const JFLTransformerErrorHandlingErrorDomain;

extern const NSInteger JFLTransformerErrorHandlingErrorInvalidInput;

extern NSString * const JFLTransformerErrorHandlingInputValueErrorKey;

@protocol JFLTransformerErrorHandling <NSObject>

@required
- (id)transformedValue:(id)value success:(BOOL *)success error:(NSError **)error;

@optional
- (id)reverseTransformedValue:(id)value success:(BOOL *)success error:(NSError **)error;

@end
