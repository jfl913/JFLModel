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
        return NULL;
    }
    
    const char *typeString = attrString + 1;
    const char *next = NSGetSizeAndAlignment(typeString, NULL, NULL);
    if (!next) {
        fprintf(stderr, "ERROR: Cound not read past type in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
        return NULL;
    }
    
    size_t typeLength = next - typeString;
    if (!typeLength) {
        fprintf(stderr, "ERROR: Invalid type in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
        return NULL;
    }
    
    // allocate enough space for the structure and the type string (plus a NUL)
    jfl_propertyAttributes *attributes = calloc(1, sizeof(jfl_propertyAttributes) + typeLength + 1);
    if (!attributes) {
        fprintf(stderr, "ERROR: Could not allocate jfl_propertyAttributes structure for attribute string \"%s\" for property %s\n", attrString, property_getName(property));
        return NULL;
    }
    
    strncpy(attributes->type, typeString, typeLength);
    attributes->type[typeLength] = '\0';
    
    // if this is an object type, and immediately followed by a quoted string...
    if (typeString[0] == *(@encode(id)) && typeString[1] == '"') {
        // we should be able to extract a class name
        const char *className = typeString + 2;
        next = strchr(className, '"');
        if (!next) {
            fprintf(stderr, "ERROR: Could not read class name in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
            return NULL;
        }
        
        if (className != next) {
            size_t classNameLength = next - className;
            char trimmedName[classNameLength + 1];
            strncpy(trimmedName, className, classNameLength);
            trimmedName[classNameLength] = '\0';
            
            // attempt to look up the class in the runtime
            // 得到属性的类名
            attributes->objectClass = objc_getClass(trimmedName);
        }
    }
    
    if (*next != '\0') {
        // skip past any junk befor the first flag
        next = strchr(next, ',');
    }
    
    // 得到变量的属性，例如assign，copy，retain等
    while (next && *next == ',') {
        char flag = next[1];
        next += 2;
        
        switch (flag) {
            case '\0':
                break;
                
            case 'R':
                attributes->readonly = YES;
                break;
            
            case 'C':
                attributes->memoryManagementPolicy = jfl_propertyMemoryManagementPolicyCopy;
                break;
            
            case '&':
                attributes->memoryManagementPolicy = jfl_propertyMemoryManagementPolicyRetain;
                break;
                
            case 'N':
                attributes->nonatomic = YES;
                break;
                
            case 'G':
            case 'S':
                {
                    const char *nextFlag = strchr(next, ',');
                    SEL name = NULL;
                    
                    if (!nextFlag) {
                        // asssume that the rest of the string is the selector
                        const char *selectorString = next;
                        next = "";
                        
                        name = sel_registerName(selectorString);
                    } else {
                        size_t selectorLength = nextFlag - next;
                        if (!selectorLength) {
                            fprintf(stderr, "ERROR: Found zero length selector name in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
                            goto errorOut;
                        }
                        
                        char selectorString[selectorLength + 1];
                        strncpy(selectorString, next, selectorLength);
                        selectorString[selectorLength] = '\0';
                        
                        name = sel_registerName(selectorString);
                        next = nextFlag;
                    }
                    
                    if (flag == 'G') {
                        attributes->getter = name;
                    } else {
                        attributes->setter = name;
                    }
                }
                
                break;
                
            case 'D':
                attributes->dynamic = YES;
                attributes->ivar = NULL;
                break;
                
            case 'V':
                // assume that the rest of the string (if present) is the ivar name
                if (*next == '\0') {
                    attributes->ivar = NULL;
                } else {
                    attributes->ivar = next;
                    next = "";
                }
            
                break;
            
            case 'W':
                attributes->weak = YES;
                break;
                
            case 't':
                fprintf(stderr, "ERROR: Old-style type encoding is unsupported in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
                
                // skip over this type encoding
                while (*next != ',' && *next != '\0') {
                    ++next;
                }
                
                break;
 
            default:
                fprintf(stderr, "ERROR: Unrecognized attribute string flag '%c' in attribute string \"%s\" for property %s\n", flag, attrString, property_getName(property));
                break;
        }
    }
    
    if (next && *next != '\0') {
        fprintf(stderr, "");
    }
    
    
errorOut:
    free(attributes);
    return NULL;
}