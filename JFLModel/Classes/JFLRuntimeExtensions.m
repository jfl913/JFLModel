//
//  JFLRuntimeExtensions.m
//  Pods
//
//  Created by JunfengLi on 16/9/17.
//
//

#import "JFLRuntimeExtensions.h"

// The string starts with a T followed by the @encode type and a comma, and finishes with a V followed by the name of the backing instance variable. Between these, the attributes are specified by the following descriptors, separated by commas
// https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html

jfl_propertyAttributes *jfl_copyPropertyAttributes (objc_property_t property)
{
    const char * const attrString = property_getAttributes(property);
    if (!attrString) {
        fprintf(stderr, "ERROR: Cound not get attribute string from property %s\n", property_getName(property));
        return NULL;
    }
    
    if (attrString[0] != 'T') {
        fprintf(stderr, "ERROR: Expected attribute string \"%s\" for property %s to start with 'T'\n", attrString, property_getName(property));
    }
    
    const char *typeString = attrString + 1;
    
}