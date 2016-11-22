//
//  NSError+JFLModelException.h
//  Pods
//
//  Created by LiJunfeng on 2016/11/22.
//
//

#import <Foundation/Foundation.h>

@interface NSError (JFLModelException)

+ (instancetype)jfl_modelErrorWithException:(NSException *)exception;

@end
