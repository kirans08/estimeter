//
//  CameraOverlay.h
//  OverlayView
//
//  Created by user on 21/04/15.
//  Copyright (c) 2015 user. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import "ViewController.h"
@interface CameraOverlay : UIView <UIActionSheetDelegate>
{
    CMMotionManager *motionManager;

    UISlider *heightSlider ;

    UIButton *measureDimensionButton;
    UIButton *measureDistanceButton;
    UIButton *measureHeightButton;
    UIButton *heightInfoButton;
    UIButton *distanceInfoButton;
    UIButton *dimensionInfoButton;

    UIButton *infoButton;
    UIButton *homeButton;
    UIButton *unitPickerButton;

    UIButton *calibrateButton;
    UIButton *recalibrateButton;
    UIButton *captureButton;
    UIButton *markBaseButton;
    UIButton *markPositon1Button;

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
    UIImageView *indicatorView;

    NSTimer *timer;
    NSTimer *timer1;
    NSTimer *timer2;
}

@property (nonatomic, strong) ViewController *viewController;
- (float)sliderThumbPosition:(UISlider *)slider;
-(void)setMenuView:(BOOL)value forDistance:(float)distanceValue;

@end
