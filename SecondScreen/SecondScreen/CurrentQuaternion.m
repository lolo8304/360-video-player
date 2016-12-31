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

@interface CurrentQuaternion ()
@property (strong, nonatomic) NSMutableArray* queue;
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
    return self;
}

- (void) enqueue: (float) x add: (float) y add: (float) z add: (float) w {
    Quaternion* q = [[Quaternion alloc] initWith:x with:y with:z with:w];
    @synchronized(self.queue) {
        [self.queue addObject: q];
        if (self.queue.count > 10) {
            [self.queue removeObjectAtIndex: 0];
        }
    }
}
- (Quaternion*) dequeue {
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
- (int)count {
    @synchronized(self.queue) {
        return (int)self.queue.count;
    }
}



@end
