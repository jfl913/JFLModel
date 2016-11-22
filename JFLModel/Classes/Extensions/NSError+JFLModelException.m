//
//  NSError+JFLModelException.m
//  Pods
//
//  Created by LiJunfeng on 2016/11/22.
//
//

#import "NSError+JFLModelException.h"

static NSString * const JFLModelErrorDomain = @"JFLModelErrorDomain";
static const NSInteger JFLModelErrorExceptionThrown = 1;
static NSString * const JFLModelThrownExceptionErrorKey = @"JFLModelThrownException";

@implementation NSError (JFLModelException)

+ (instancetype)jfl_modelErrorWithException:(NSException *)exception
{
    NSParameterAssert(exception != nil);
    
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: exception.description,
                               NSLocalizedFailureReasonErrorKey: exception.reason,
                               JFLModelThrownExceptionErrorKey: exception,
                               };
    
    return [NSError errorWithDomain:JFLModelErrorDomain
                               code:JFLModelErrorExceptionThrown
                           userInfo:userInfo];
}

@end
