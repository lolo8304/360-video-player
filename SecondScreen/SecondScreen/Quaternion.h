//
//  Quaternion.h
//  SecondScreen
//
//  Created by Lorenz Hänggi on 31.12.16.
//  Copyright © 2016 Lorenz Hänggi. All rights reserved.
//

@interface Quaternion : NSObject


- (id) initWith: (float) X with: (float) Y with: (float) Z with: (float) W;

- (float)pitch;
- (float)roll;
- (float)yaw;


@end
