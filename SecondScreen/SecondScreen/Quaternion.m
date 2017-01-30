//
//  Quaternion.m
//  SecondScreen
//
//  Created by Lorenz Hänggi on 31.12.16.
//  Copyright © 2016 Lorenz Hänggi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Quaternion.h"

@interface Quaternion ()

    @property (assign, nonatomic, readonly) int seek;
    @property (assign, nonatomic, readonly) float x;
    @property (assign, nonatomic, readonly) float y;
    @property (assign, nonatomic, readonly) float z;
    @property (assign, nonatomic, readonly) float w;
@end

@implementation Quaternion 

- (id) initWith: (int) seek with:(float)X with:(float)Y with:(float)Z with:(float)W {
    _x = X;
    _y = Y;
    _z = Z;
    _w = W;
    _seek = seek;
    return self;
}

// https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles#Source_Code_2

- (float) roll {
    // atan2(2*qy*qw-2*qx*qz , 1 - 2*qy2 - 2*qz2)
    return atan2f(2.0f * self.y * self.w - 2.0f * self.x * self.z, 1.0f - 2.0 * self.y * self.y - 2.0f * self.z * self.z);
    //    return atan2(2*(self.x*self.y + self.w*self.z), self.w*self.w + self.x*self.x - self.y*self.y - self.z*self.z);
}
- (float) yaw {
    // asin(2*qx*qy + 2*qz*qw)
    return asinf(2.0f * self.x * self.y + 2.0f * self.z * self.w);
    
//    return asin(-2*(self.x*self.z - self.w*self.y));
}
- (float) pitch {
    // atan2(2*qx*qw-2*qy*qz , 1 - 2*qx2 - 2*qz2)
    return atan2f( 2.0f * self.x * self.w - 2.0f * self.y * self.z, 1.0f - 2 * self.x * self.x - 2 * self.z * self.z);
    // return atan2(2*(self.y*self.z + self.w*self.x), self.w*self.w - self.x*self.x - self.y*self.y + self.z*self.z);
}



@end
