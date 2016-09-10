//
//  JFLModel.h
//  Pods
//
//  Created by LiJunfeng on 16/9/10.
//
//

#import <Foundation/Foundation.h>

@protocol JFLModel <NSObject>

+ (NSSet *)propertyKeys;

@end

@interface JFLModel : NSObject <JFLModel>

@end
