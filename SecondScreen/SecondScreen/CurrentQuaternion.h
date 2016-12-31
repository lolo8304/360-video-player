//
//  CurrentQuaternion.h
//  SecondScreen
//
//  Created by Lorenz Hänggi on 31.12.16.
//  Copyright © 2016 Lorenz Hänggi. All rights reserved.
//

#import "Quaternion.h"

@interface CurrentQuaternion : NSObject

@property (assign, nonatomic, readonly) float x;
@property (assign, nonatomic, readonly) float y;
@property (assign, nonatomic, readonly) float z;
@property (assign, nonatomic, readonly) float w;


+ (CurrentQuaternion*)instance;
- (id) init;

- (void) enqueue: (float) x add: (float) y add: (float) z add: (float) w;
- (Quaternion*) dequeue;
- (int)count;

@end
