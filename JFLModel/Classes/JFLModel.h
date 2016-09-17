//
//  JFLModel.h
//  Pods
//
//  Created by LiJunfeng on 16/9/10.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, JFLPropertyStorage) {
    JFLPropertyStorageNone,
    JFLPropertyStorageTransitory,
    JFLPropertyStoragePermanent,
};

@protocol JFLModel <NSObject>

+ (NSSet *)propertyKeys;

@end

@interface JFLModel : NSObject <JFLModel>

@end
