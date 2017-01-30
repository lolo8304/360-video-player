//
//  EulerianAngle.m
//  SecondScreen
//
//  Created by Lorenz Hänggi on 31.12.16.
//  Copyright © 2016 Lorenz Hänggi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EulerianAngle.h"

@interface EulerianAngle ()
@end

@implementation EulerianAngle

- (id) initWith: (int) seek with:(float)pitchX with:(float)rollY with:(float)yawZ {
    _pitch = pitchX;
    _roll = rollY;
    _yaw = yawZ;
    _seek = seek;
    return self;
}

@end
