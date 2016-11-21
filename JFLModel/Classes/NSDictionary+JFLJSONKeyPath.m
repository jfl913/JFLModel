//
//  NSDictionary+JFLJSONKeyPath.m
//  Pods
//
//  Created by LiJunfeng on 2016/11/21.
//
//

#import "NSDictionary+JFLJSONKeyPath.h"
#import "JFLJSONAdapter.h"

@implementation NSDictionary (JFLJSONKeyPath)

- (id)jfl_valueForJSONKeyPath:(NSString *)JSONKeyPath success:(BOOL *)success error:(NSError **)error
{
    NSArray *components = [JSONKeyPath componentsSeparatedByString:@"."];
    
    id result = self;
    for (NSString *component in components) {
        if (result == nil || result == NSNull.null) break;
        
        if (![result isKindOfClass:[NSDictionary class]]) {
            if (error != NULL) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid JSON dictionary", @""),
                                           NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"JSON key path %1$@ could not resolved because an incompatible JSON dictionary was supplied: \"%2$@\"", @""), JSONKeyPath, self]
                                           };
                *error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:JFLJSONAdapterErrorInvalidJSONDictionary userInfo:userInfo];
            }
            
            if (success != NULL) *success = NO;
            
            return nil;
        }
        
        result = result[JSONKeyPath];
    }
    
    if (success != NULL) *success = YES;
    
    return result;
}

@end
