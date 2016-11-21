//
//  NSDictionary+JFLJSONKeyPath.h
//  Pods
//
//  Created by LiJunfeng on 2016/11/21.
//
//

#import <Foundation/Foundation.h>

@interface NSDictionary (JFLJSONKeyPath)

- (id)jfl_valueForJSONKeyPath:(NSString *)JSONKeyPath success:(BOOL *)success error:(NSError **)error;

@end
