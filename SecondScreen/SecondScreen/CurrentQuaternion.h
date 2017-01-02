//
//  CurrentQuaternion.h
//  SecondScreen
//
//  Created by Lorenz Hänggi on 31.12.16.
//  Copyright © 2016 Lorenz Hänggi. All rights reserved.
//

#import "Quaternion.h"

@interface CurrentQuaternion : NSObject

+ (CurrentQuaternion*)instance;
- (id) init;

- (void) enqueue: (float) x add: (float) y add: (float) z add: (float) w;
- (void) enqueue: (float) pitchX add: (float) rollY add: (float) yawZ;
- (NSObject<QuaternionAPI>*) dequeue;
- (NSObject<QuaternionAPI>*) dequeueLast;
- (void)reset;
- (int)count;
- (int)maxCount;
- (void)play;
- (void)stop;

@end
