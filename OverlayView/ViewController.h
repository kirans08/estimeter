//
//  ViewController.h
//  OverlayView
//
//  Created by user on 21/04/15.
//  Copyright (c) 2015 user. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <QuartzCore/QuartzCore.h>
#import "ImagePickerViewController.h"


@interface ViewController : UIViewController <UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate>
{
    CMMotionManager *motionManager;
    NSTimer *timer;
    UILabel *distanceOutput;
}

@property (weak, nonatomic) IBOutlet UIButton *point1Button;
@property (weak, nonatomic) IBOutlet UIButton *point2Button;
@property (strong, nonatomic) IBOutlet UIImageView *capturedImageView;

- (IBAction)pointButtonDrag:(id)sender withEvent:(UIEvent *) event ;
- (IBAction)goBack:(id)sender;
- (IBAction)goToHome:(id)sender;
- (IBAction)viewGuide:(id)sender;


- (IBAction)selectUnits:(id)sender;
- (void)callBack:(float) distance ;
- (void)setTypeAsCamera;
- (void)setTypeAsVideo;
@end

