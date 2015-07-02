//
//  ScanButton.m
//  OverlayView
//
//  Created by user on 21/04/15.
//  Copyright (c) 2015 user. All rights reserved.
//

#import "ScanButton.h"
#import <CoreMotion/CoreMotion.h>
#import "ViewController.h"
@implementation ScanButton

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Set button image:
        UIImageView *buttonImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
        buttonImage.image = [UIImage imageNamed:@"scanbutton.png"];
        
        [self addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside]; // for future use
        
        CMAttitude *attitude;
        CMDeviceMotion *motion = motionManager.deviceMotion;
        attitude =motion.attitude;
        NSString *pitch1=[NSString stringWithFormat:@"%f",attitude.pitch];
        
        NSLog(@"%@",pitch1);
        
        
        
        
        
        
        [self addSubview:buttonImage];
    }
    return self;
}

- (void)buttonPressed {
    // TODO: Could toggle a button state and/or image
}

@end
