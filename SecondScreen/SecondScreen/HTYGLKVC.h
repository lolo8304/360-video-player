//
//  HTYGLKVC.h
//  HTY360Player
//
//  Created by  on 11/8/15.
//  Copyright © 2015 Hanton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@class HTY360PlayerVC;

@interface HTYGLKVC : GLKViewController <UIGestureRecognizerDelegate>
typedef NS_ENUM(NSUInteger, MotionType) {
    kUsingDeviceMotion,
    kUsingRemoteMotion,
    kUsingFingerMotion
};

@property (strong, nonatomic, readwrite) HTY360PlayerVC* videoPlayerController;
@property (assign, nonatomic, readonly) BOOL isUsingMotion;
@property (assign, nonatomic, readonly) MotionType motionType;

- (void)startDeviceMotion;
- (void)startRemoteMotion;
- (void)startFingerMotion;

@end
