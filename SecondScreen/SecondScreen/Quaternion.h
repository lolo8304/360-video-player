//
//  Quaternion.h
//  SecondScreen
//
//  Created by Lorenz Hänggi on 31.12.16.
//  Copyright © 2016 Lorenz Hänggi. All rights reserved.
//

@protocol QuaternionAPI <NSObject>

- (int)seek;
- (float)pitch;
- (float)roll;
- (float)yaw;

@end

@interface Quaternion : NSObject<QuaternionAPI>

- (id) initWith: (int) seek with: (float) X with: (float) Y with: (float) Z with: (float) W;

@end
