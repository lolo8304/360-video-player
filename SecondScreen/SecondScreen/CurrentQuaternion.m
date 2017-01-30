//
//  CurrentQuaternion.m
//  SecondScreen
//
//  Created by Lorenz Hänggi on 31.12.16.
//  Copyright © 2016 Lorenz Hänggi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CurrentQuaternion.h"
#import "Quaternion.h"
#import "EulerianAngle.h"



@interface PlayerAction ()
@end


@interface CurrentQuaternion ()
@property (strong, nonatomic) NSMutableArray* queue;
@property (strong, nonatomic) NSMutableArray* playerActionQueue;
@property (atomic) BOOL playing;
@end

@implementation PlayerAction
- (id) init: (NSObject*) player stopAt: (int) seek {
    self.player = player;
    self.type = kStop;
    self.seek = -1;
    self.name = nil;
    self.mediaName = nil;
    self.mediaExtension = nil;
    self.mediaURL = nil;
    return self;
}

- (id) init: (NSObject*) player seekAt: (int) seek {
    self.player = player;
    self.type = kSeek;
    self.seek = seek;
    self.name = nil;
    self.mediaName = nil;
    self.mediaExtension = nil;
    self.mediaURL = nil;
    return self;
}
- (id) init: (NSObject*) player playAt: (int) seek {
    self.player = player;
    self.type = kPlayAt;
    self.seek = seek;
    self.name = nil;
    self.mediaName = nil;
    self.mediaExtension = nil;
    self.mediaURL = nil;
    return self;
}
- (id) init: (NSObject*) player pauseAt: (int) seek {
    self.player = player;
    self.type = kPauseAt;
    self.seek = seek;
    self.name = nil;
    self.mediaName = nil;
    self.mediaExtension = nil;
    self.mediaURL = nil;
    return self;
}
- (id) init: (NSObject*) player prepareVideo: (NSString*) name mediaName: (NSString*) mediaName ext: (NSString*) ext at: (int) seek {
    self.player = player;
    self.type = kPlayNewVideo;
    self.seek = seek;
    self.name = name;
    self.mediaName = mediaName;
    self.mediaExtension = ext;
    self.mediaURL = nil;
    return self;
}
- (id) init: (NSObject*) player prepareVideo: (NSString*) name mediaURL: (NSURL*) mediaURL ext: (NSString*) ext at: (int) seek {
    self.player = player;
    self.type = kPlayNewVideo;
    self.seek = seek;
    self.name = name;
    self.mediaName = nil;
    self.mediaExtension = ext;
    self.mediaURL = mediaURL;
    return self;
}
- (NSURL*) getURL {
    if (self.mediaURL != nil) {
        return self.mediaURL;
    } else {
        NSString* path = [[NSBundle mainBundle] pathForResource: self.mediaName ofType: self.mediaExtension];
        return [NSURL fileURLWithPath: path];
    }
}


@end

@implementation CurrentQuaternion

+ (CurrentQuaternion*)instance {
    static CurrentQuaternion *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (id) init {
    self.queue = [[NSMutableArray alloc] init];
    self.playerActionQueue = [[NSMutableArray alloc] init];
    self.playing = false;
    return self;
}

- (void) enqueue: (int) seek add: (float) x add: (float) y add: (float) z add: (float) w {
    if (!self.playing) { return; }
    Quaternion* q = [[Quaternion alloc] initWith: seek with:x with:y with:z with:w];
    @synchronized(self.queue) {
        [self.queue addObject: q];
        if (self.queue.count > 2) {
            [self.queue removeObjectAtIndex: 0];
        }
        //self.maxQueue = MAX(self.maxQueue, self.queue.count);
        //NSLog(@"max queue = %lu", self.maxQueue);
    }
}
- (void)enqueue: (int)seek add: (float) pitchX add:(float)rollY add:(float)yawZ {
    if (!self.playing) { return; }
    EulerianAngle* q = [[EulerianAngle alloc] initWith: seek with:pitchX with:rollY with:yawZ];
    @synchronized(self.queue) {
        [self.queue addObject: q];
        if (self.queue.count > 2) {
            [self.queue removeObjectAtIndex: 0];
        }
        //self.maxQueue = MAX(self.maxQueue, self.queue.count);
        //NSLog(@"max queue = %lu", self.maxQueue);
    }
}

- (NSObject<QuaternionAPI>*) dequeue {
    @synchronized(self.queue) {
        if (self.queue.count > 0) {
            Quaternion* q = self.queue[0];
            [self.queue removeObjectAtIndex: 0];
            return q;
        } else {
            return nil;
        }
    }
}
- (NSObject<QuaternionAPI>*) dequeueLast {
    @synchronized(self.queue) {
        if (self.queue.count > 0) {
            Quaternion* q = self.queue[self.queue.count-1];
            [self.queue removeLastObject];
            return q;
        } else {
            return nil;
        }
    }
}
- (int)count {
    @synchronized(self.queue) {
        return (int)self.queue.count;
    }
}
- (int)playerActionCount {
    @synchronized(self.playerActionQueue) {
        return (int)self.playerActionQueue.count;
    }
}

- (void)reset {
    self.queue = [[NSMutableArray alloc] init];
    self.playerActionQueue = [[NSMutableArray alloc] init];
}

- (void)play {
    if (self.playing) { [self reset]; }
    self.playing = true;
}
- (void)stop {
    [self reset];
    self.playing = false;
}


- (void) enqueuePlayerAction: (PlayerAction*) playerAction {
    @synchronized(self.playerActionQueue) {
        [self.playerActionQueue addObject: playerAction];
        if (self.playerActionQueue.count > 3) {
            [self.playerActionQueue removeObjectAtIndex: 0];
        }
    }
    
}
- (PlayerAction*) dequeuePlayerAction: (NSObject*) player {
    @synchronized(self.playerActionQueue) {
        if (self.playerActionQueue.count > 0) {
            PlayerAction* a = self.playerActionQueue[0];
            [self.playerActionQueue removeObjectAtIndex: 0];
            if (a.player == player) {
                return a;
            } else {
                return [self dequeuePlayerAction: player];
            }
        } else {
            return nil;
        }
    }
}

@end
