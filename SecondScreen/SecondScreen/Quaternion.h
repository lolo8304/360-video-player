//
//  Quaternion.h
//  SecondScreen
//
//  Created by Lorenz Hänggi on 31.12.16.
//  Copyright © 2016 Lorenz Hänggi. All rights reserved.
//

@protocol QuaternionAPI <NSObject>

- (float)pitch;
- (float)roll;
- (float)yaw;

@end

@interface Quaternion : NSObject<QuaternionAPI>

- (id) initWith: (float) X with: (float) Y with: (float) Z with: (float) W;

@end
