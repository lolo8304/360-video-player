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

@interface CurrentQuaternion ()
@property (strong, nonatomic) NSMutableArray* queue;
@property (atomic) unsigned long maxQueue;
@property (atomic) BOOL playing;

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
    self.maxQueue = 0;
    self.playing = false;
    return self;
}

- (void) enqueue: (float) x add: (float) y add: (float) z add: (float) w {
    if (!self.playing) { return; }
    Quaternion* q = [[Quaternion alloc] initWith:x with:y with:z with:w];
    @synchronized(self.queue) {
        [self.queue addObject: q];
        if (self.queue.count > 10) {
            [self.queue removeObjectAtIndex: 0];
        }
        self.maxQueue = MAX(self.maxQueue, self.queue.count);
        //NSLog(@"max queue = %lu", self.maxQueue);
    }
}
- (void)enqueue:(float)pitchX add:(float)rollY add:(float)yawZ {
    if (!self.playing) { return; }
    EulerianAngle* q = [[EulerianAngle alloc] initWith:pitchX with:rollY with:yawZ];
    @synchronized(self.queue) {
        [self.queue addObject: q];
        if (self.queue.count > 10) {
            [self.queue removeObjectAtIndex: 0];
        }
        self.maxQueue = MAX(self.maxQueue, self.queue.count);
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

- (void)reset {
    self.queue = [[NSMutableArray alloc] init];
    self.maxQueue = 0;
}

- (void)play {
    if (self.playing) { [self reset]; }
    self.playing = true;
}
- (void)stop {
    [self reset];
    self.playing = false;
}



@end
