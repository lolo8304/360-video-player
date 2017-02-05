//
//  HTY360PlayerVC.h
//  HTY360Player
//
//  Created by  on 11/8/15.
//  Copyright © 2015 Hanton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "CurrentQuaternion.h"

@protocol HTY360PlayerVCDelegate <NSObject>
- (void)videoPlayerDuration: (double) duration;
- (NSString*)videoPlayerTitle;
- (void)videoSaveSnapshot: (UIImage*) image;
@end

@interface HTY360PlayerVC : UIViewController

@property (strong, nonatomic) NSURL *videoURL;
@property (strong, nonatomic) NSObject *devicePlayer;
@property (nonatomic) id<HTY360PlayerVCDelegate> playerDelegate;

- (id)initWith: (NSObject*) devicePlayer nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil url:(NSURL*)url;
- (id)initWith: (NSObject*) devicePlayer nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil name:(NSString*)name ext: (NSString*) ext;
- (CVPixelBufferRef)retrievePixelBufferToDraw;
- (void)toggleControls;

- (BOOL)runPlayerAction: (PlayerAction*) action;

@end
