//
//  JFLJSONAdapter.h
//  Pods
//
//  Created by LiJunfeng on 16/9/10.
//
//

#import <Foundation/Foundation.h>

@interface JFLJSONAdapter : NSObject

+ (id)modelOfClass:(Class)modelClass
         fromModel:(id)model
             error:(NSError *)error;

+ (NSDictionary *)JSONDictionaryFromModel:(id)model
                                    error:(NSError *)error;

+ (id)modelOfClass:(Class)modelClass
fromJSONDictionary:(NSDictionary *)JSONDictionary
             error:(NSError *)error;

@end
