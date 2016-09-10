//
//  JFLJSONAdapter.m
//  Pods
//
//  Created by LiJunfeng on 16/9/10.
//
//

#import "JFLJSONAdapter.h"

@implementation JFLJSONAdapter

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

+ (NSDictionary *)JSONDictionaryFromModel:(id)model
                                    error:(NSError *)error
{
    return @{};
}

+ (id)modelOfClass:(Class)modelClass
fromJSONDictionary:(NSDictionary *)JSONDictionary
             error:(NSError *)error
{
    return nil;
}

@end
