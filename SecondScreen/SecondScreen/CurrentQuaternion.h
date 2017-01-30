//
//  CurrentQuaternion.h
//  SecondScreen
//
//  Created by Lorenz Hänggi on 31.12.16.
//  Copyright © 2016 Lorenz Hänggi. All rights reserved.
//

#import "Quaternion.h"

typedef NS_ENUM(NSUInteger, PlayerActionType) {
    kSeek,
    kPlayAt,
    kPauseAt,
    kStop,
    kPlayNewVideo
};

@interface PlayerAction : NSObject
@property (atomic) NSObject* player;
@property (atomic) PlayerActionType type;
@property (atomic) int seek;
@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSString* mediaName;
@property (strong, nonatomic) NSString* mediaExtension;
@property (strong, nonatomic) NSURL* mediaURL;

- (id) init: (NSObject*) player seekAt: (int) seek;
- (id) init: (NSObject*) player playAt: (int) seek;
- (id) init: (NSObject*) player pauseAt: (int) seek;
- (id) init: (NSObject*) player stopAt: (int) seek;
- (id) init: (NSObject*) player prepareVideo: (NSString*) name mediaName: (NSString*) mediaName ext: (NSString*) ext at: (int) seek;
- (id) init: (NSObject*) player prepareVideo: (NSString*) name mediaURL: (NSURL*) mediaURL ext: (NSString*) ext at: (int)seek;

- (NSURL*) getURL;
@end

@interface CurrentQuaternion : NSObject

+ (CurrentQuaternion*)instance;
- (id) init;

- (void) enqueue: (int) seek add: (float) x add: (float) y add: (float) z add: (float) w;
- (void) enqueue: (int) seek add: (float) pitchX add: (float) rollY add: (float) yawZ;
- (NSObject<QuaternionAPI>*) dequeue;
- (NSObject<QuaternionAPI>*) dequeueLast;
- (void)reset;
- (int)count;
- (void)play;
- (void)stop;

- (void) enqueuePlayerAction: (PlayerAction*) playerAction;
- (PlayerAction*) dequeuePlayerAction: (NSObject*) player;


@end
