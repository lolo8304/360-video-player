//
//  EulerianAngle.h
//  SecondScreen
//
//  Created by Lorenz Hänggi on 31.12.16.
//  Copyright © 2016 Lorenz Hänggi. All rights reserved.
//

#import "Quaternion.h"

@interface EulerianAngle : NSObject<QuaternionAPI>

@property (assign, nonatomic, readonly) float roll;
@property (assign, nonatomic, readonly) float pitch;
@property (assign, nonatomic, readonly) float yaw;

- (id) initWith: (float) pitchX with: (float) rollY with: (float) yawZ;

@end
