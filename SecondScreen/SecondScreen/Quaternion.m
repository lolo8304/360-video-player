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
    @property (assign, nonatomic, readonly) float x;
    @property (assign, nonatomic, readonly) float y;
    @property (assign, nonatomic, readonly) float z;
    @property (assign, nonatomic, readonly) float w;
@end

@implementation Quaternion

- (id) initWith:(float)X with:(float)Y with:(float)Z with:(float)W {
    _x = X;
    _y = Y;
    _z = Z;
    _w = W;
    return self;
}

- (float) roll {
    return atan2(2*(self.x*self.y + self.w*self.z), self.w*self.w + self.x*self.x - self.y*self.y - self.z*self.z);
}
- (float) yaw {
    return asin(-2*(self.x*self.z - self.w*self.y));
}
- (float) pitch {
    return atan2(2*(self.y*self.z + self.w*self.x), self.w*self.w - self.x*self.x - self.y*self.y + self.z*self.z);
}



@end
