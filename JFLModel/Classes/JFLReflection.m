//
//  JFLReflection.m
//  Pods
//
//  Created by LiJunfeng on 2016/10/19.
//
//

#import "JFLReflection.h"
#import <objc/runtime.h>

SEL JFLSelectorWithKeyPattern(NSString *key, const char *suffix)
{
    NSUInteger keyLength = [key maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    NSUInteger suffixLength = strlen(suffix);
    
    char selector[keyLength + suffixLength + 1];
    
    BOOL success = [key getBytes:selector
                       maxLength:keyLength
                      usedLength:&keyLength
                        encoding:NSUTF8StringEncoding
                         options:0
                           range:NSMakeRange(0, key.length)
                  remainingRange:NULL];
    
    if (!success) return NULL;
    
    memcpy(selector + keyLength, suffix, suffixLength);
    selector[keyLength + suffixLength] = '\0';
    
    return sel_registerName(selector);
}
