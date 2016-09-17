//
//  JFLRuntimeExtensions.h
//  Pods
//
//  Created by JunfengLi on 16/9/17.
//
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

typedef NS_ENUM(NSUInteger, jfl_propertyMemoryManagementPolicy) {
    jfl_propertyMemoryManagementPolicyAssign,
    jfl_propertyMemoryManagementPolicyRetain,
    jfl_propertyMemoryManagementPolicyCopy,
};

struct jfl_propertyAttributes {
    BOOL readonly;
    BOOL nonatomic;
    BOOL weak;
    BOOL canBeCollected;
    BOOL dynamic;
    jfl_propertyMemoryManagementPolicy memoryManagementPolicy;
    SEL getter;
    SEL setter;
    const char *ivar;
    Class objectClass;
    char type[];
};