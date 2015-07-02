//
//  oV.h
//  OverlayView
//
//  Created by user on 21/04/15.
//  Copyright (c) 2015 user. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import "ViewController.h"
@interface CameraOverlay : UIView
{
    CMMotionManager *motionManager;
    UISlider *heightSlider ;
    UIButton *calibrateButton;
    UIButton *recalibrateButton;
    UIButton *captureButton;
    UIButton *markBaseButton;
    UIButton *measureDimensionButton;
    UIButton *measureDistanceButton;
    UIButton *measureHeightButton;
    UIButton *markPositon1Button;
    
    
    UIButton *infoButton;
     UIButton *heightInfoButton;
     UIButton *distanceInfoButton;
     UIButton *dimensionInfoButton;
    UIButton *homeButton;
    UIButton *unitPickerButton;
    UILabel *sliderValueLabel ;
    UILabel *heightOutputLabel ;
    UILabel *distanceOutputlabel1;
    UILabel *distanceOutputlabel2;
    UILabel *distanceOutputlabel3;
    
    UIView *guideBackground;
    UIView *guideBackground1;
    
    UIImageView *backgroundImageView;
    UIImageView *guideImageView;
    UIImageView *guideImageView1;
    NSTimer *timer;
    NSTimer *timer1;
    NSTimer *timer2;
    
    ///////////////////FOR TEST ONLY
     UILabel *t;
    ////////////////////////////////
}

@property (nonatomic, strong) ViewController *viewController;
- (float)sliderThumbPosition:(UISlider *)slider;
-(void)setMenuView:(BOOL)value;
@end
