//
//  ScanButton.h
//  OverlayView
//
//  Created by user on 21/04/15.
//  Copyright (c) 2015 user. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
@interface ScanButton : UIControl {
       CMMotionManager *motionManager;
}

- (void)buttonPressed;

@end