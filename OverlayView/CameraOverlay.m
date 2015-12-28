//
//  CameraOverlay.m
//  OverlayView
//
//  Created by user on 21/04/15.
//  Copyright (c) 2015 user. All rights reserved.
//

#import "CameraOverlay.h"
#import "Constants.h"

@implementation CameraOverlay

float distance, cameraHeight, deviceFrameWidth, deviceFrameHeight;
int initialPosition, finalPostion, previousPosition, nextGuide, currentMeasuringMode, currentUnit;
bool objectHigherThanCamera, showHeightGuide, showDistanceGuide, showDimensionGuide, firstRun, yawChange;
UIImageView *crossHairView, *infoImageView;
UIImage *green, *red, *orange;

- (id)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        
        [self initialiseGlobalVariables];
        [self initialiseMotionManager];
        [self checkIfIsFirstLaunch];
        [self createMainMenu];
        [self createMainMenuInfoButtons];
        [self createCrossHair:frame];
        [self createTopBar];
        [self createDimensionMeasureWindow];
        [self createDistanceMeasureWindow];
        [self createHeightMeasureWindow];
        
    }
    return self;
}

//For initialising global variables
- (void)initialiseGlobalVariables {
    
    firstRun = NO;
    showDimensionGuide = NO;
    showDistanceGuide = NO;
    showHeightGuide = NO;
    
    cameraHeight = INITAL_CAMERA_HEIGHT;
 
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    deviceFrameWidth = screenRect.size.width;
    deviceFrameHeight = screenRect.size.height;
    
    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
    
    
}

//For Initialising motion manager
- (void)initialiseMotionManager {
    
    motionManager = [[CMMotionManager alloc]init];
    motionManager.deviceMotionUpdateInterval = MOTION_UPDATE_INTERVAL;
    [motionManager startGyroUpdates];
    [motionManager startDeviceMotionUpdates];
    [motionManager startAccelerometerUpdates];
    
}

//For displaying the tutorial guides on first launch
- (void)checkIfIsFirstLaunch {
    
    BOOL multiRun;
    multiRun = [[NSUserDefaults standardUserDefaults] boolForKey:@"isRunMoreThanOnce"];
    
    if(!multiRun) {
        
        firstRun = YES;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isRunMoreThanOnce"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    }
    
    if(firstRun) {
        
        showDimensionGuide = YES;
        showDistanceGuide = YES;
        showHeightGuide = YES;
        
    }
}

//For displaying the take photo step on call back from ViewController
- (void)setMenuView:(BOOL)value forDistance:(float)distanceValue {
    
    if(!value) {
        
        [self hideMenu];
        
        crossHairView.alpha = 0;
        sliderValueLabel.alpha = 0;
        heightSlider.alpha = 0;
        distance = distanceValue;
        
        [recalibrateButton setHidden:NO];
        [captureButton setHidden:NO];
        
        nextGuide = CAPTURE_GUIDE;
        
        timer = [NSTimer scheduledTimerWithTimeInterval:HEIGHT_UPDATE_INTERVAL
                                                 target:self
                                               selector:@selector(showIndicator)
                                               userInfo:nil
                                                repeats:YES];
        
    }
    
}

#pragma mark - UI modifications

//For creating the main menu
- (void)createMainMenu {
    
    UIImage *backgroundImage = [UIImage imageNamed:@"backgroundImage.png"];
    
    backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
    backgroundImageView.alpha = 0.75;
    backgroundImageView.frame = CGRectMake(0, 0, deviceFrameWidth, deviceFrameHeight);
    
    [self addSubview:backgroundImageView];
    
    measureHeightButton = [self newButton:CGRectMake(( deviceFrameWidth - BUTTON_POSITION_FACTOR * BUTTON_WIDTH ) / 2, deviceFrameHeight / 2 - BUTTON_HEIGHT * 2 , 2 * BUTTON_WIDTH , BUTTON_HEIGHT) forTitle:@"Quick Height Measure"];
    
    measureDistanceButton = [self newButton:CGRectMake((deviceFrameWidth - BUTTON_POSITION_FACTOR * BUTTON_WIDTH) / 2, deviceFrameHeight / 2 , 2 * BUTTON_WIDTH, BUTTON_HEIGHT) forTitle:@"Distance Between Objects"];
    
    measureDimensionButton = [self newButton:CGRectMake((deviceFrameWidth - BUTTON_POSITION_FACTOR * BUTTON_WIDTH) / 2, deviceFrameHeight / 2 + BUTTON_HEIGHT * 2 , 2 * BUTTON_WIDTH, BUTTON_HEIGHT) forTitle:@"Measure Any Dimension"];
    
    
    
    [measureHeightButton  addTarget: self
                             action: @selector(startHeightCalculation)
                   forControlEvents: UIControlEventTouchDown];
    [measureDistanceButton  addTarget: self
                               action: @selector(startDistanceCalculation)
                     forControlEvents: UIControlEventTouchDown];
    [measureDimensionButton  addTarget: self
                                action: @selector(startDimensionCalculation)
                      forControlEvents: UIControlEventTouchDown];
    
    [measureHeightButton setHidden:NO];
    [measureDistanceButton setHidden:NO];
    [measureDimensionButton setHidden:NO];
    
    [self addSubview:measureDistanceButton];
    [self addSubview:measureHeightButton];
    [self addSubview:measureDimensionButton];
    
}

//For creating the info buttons in main menu
- (void)createMainMenuInfoButtons {
    
    heightInfoButton = [self newCustomButton:CGRectMake((deviceFrameWidth - INFO_BUTTON_POSITION_FACTOR * BUTTON_WIDTH) / 2 + BUTTON_WIDTH, deviceFrameHeight / 2 - BUTTON_HEIGHT * 2, BUTTON_HEIGHT, BUTTON_HEIGHT) forImage:@"infoImage.png"];
    
    distanceInfoButton = [self newCustomButton:CGRectMake((deviceFrameWidth - INFO_BUTTON_POSITION_FACTOR * BUTTON_WIDTH) / 2 + BUTTON_WIDTH, deviceFrameHeight / 2, BUTTON_HEIGHT, BUTTON_HEIGHT) forImage:@"infoImage.png"];
    
    dimensionInfoButton = [self newCustomButton:CGRectMake((deviceFrameWidth - INFO_BUTTON_POSITION_FACTOR * BUTTON_WIDTH) / 2 + BUTTON_WIDTH, deviceFrameHeight / 2 + BUTTON_HEIGHT * 2, BUTTON_HEIGHT, BUTTON_HEIGHT) forImage:@"infoImage"];
    
    
    [heightInfoButton  addTarget: self
                          action: @selector(showHeightInfo)
                forControlEvents: UIControlEventTouchDown];
    [distanceInfoButton  addTarget: self
                            action: @selector(showDistanceInfo)
                  forControlEvents: UIControlEventTouchDown];
    [dimensionInfoButton  addTarget: self
                             action: @selector(showDimensionInfo)
                   forControlEvents: UIControlEventTouchDown];
    
    
    [heightInfoButton setHidden:NO];
    [distanceInfoButton setHidden:NO];
    [dimensionInfoButton setHidden:NO];
    
    [self addSubview:heightInfoButton];
    [self addSubview:distanceInfoButton];
    [self addSubview:dimensionInfoButton];
    
}

//For displaying the crosshair on screen
- (void)createCrossHair:(CGRect)frame {
    
    float crossHairX, crossHairY;
    
    crossHairX = (deviceFrameWidth - CROSS_HAIR_WIDTH) / 2;
//    crossHairY = [[crossHairPositionForDeviceHeight objectForKey:[NSString stringWithFormat:@"%d", (int)deviceFrameHeight]] floatValue];

    

    crossHairY=(deviceFrameHeight-CROSS_HAIR_HEIGHT)/2;

    UIImage *crossHair = [UIImage imageNamed:@"crossHairImage.png"];
    
    crossHairView = [[UIImageView alloc] initWithImage:crossHair];
    crossHairView.frame = CGRectMake(crossHairX, crossHairY, CROSS_HAIR_WIDTH, CROSS_HAIR_HEIGHT);
    [crossHairView setHidden:YES];
    

    
    [self addSubview:crossHairView];
    [self createVerticalSlider:frame];
    
}

//For creating an upside down slider
- (void)createVerticalSlider:(CGRect)frame {
    
    float sliderHeight;
    
    CGAffineTransform rotateLeft = CGAffineTransformMakeRotation( - M_PI_2);
    sliderHeight = - (deviceFrameHeight - SLIDER_HEIGHT_OFFSET) / 2;
    
    UIImage *sliderThumbImage = [[UIImage imageNamed: @"slider.png"]stretchableImageWithLeftCapWidth: SLIDER_IMAGE_WIDTH
                                                                                        topCapHeight: 0];
    UIImage *sliderTrackImage = [[UIImage imageNamed: @"trans.png"] stretchableImageWithLeftCapWidth: SLIDER_IMAGE_WIDTH
                                                                                        topCapHeight: 0];
    
    heightSlider = [[UISlider alloc] initWithFrame:frame];
    heightSlider.frame=CGRectMake(sliderHeight,SLIDER_ORIGIN_OFFSET_Y_1 + ((deviceFrameHeight - SLIDER_CLEARANCE_2) / 2), deviceFrameHeight - SLIDER_CLEARANCE_1, SLIDER_WIDTH);
    
    [heightSlider addTarget:self action:@selector(adjustHeight) forControlEvents:UIControlEventValueChanged];
    [heightSlider setBackgroundColor:[UIColor clearColor]];
    
    heightSlider.minimumValue = MINIMUM_SLIDER_VALUE;
    heightSlider.maximumValue = MAXIMUM_SLIDER_VALUE;
    heightSlider.continuous = YES;
    heightSlider.value = CURRENT_SLIDER_VALUE;
    heightSlider.transform = rotateLeft;
    
    [heightSlider setThumbImage: sliderThumbImage forState: UIControlStateNormal];
    [heightSlider setHidden:YES];
    [heightSlider setMaximumTrackImage: sliderTrackImage forState: UIControlStateNormal];
    
    sliderValueLabel = [self newLabel:CGRectMake(0, [self sliderThumbPosition:heightSlider], SLIDER_VALUE_WIDTH, SLIDER_VALUE_HEIGHT)];
    sliderValueLabel.text = @"130cm";
    
    [self addSubview:heightSlider];
    [self addSubview:sliderValueLabel];
    
}

//For creating a topbar consisting of home button, unit selector button and info button
- (void)createTopBar {
    
    infoButton = [self newCustomButton:CGRectMake(deviceFrameWidth - BUTTON_HEIGHT, 0, BUTTON_HEIGHT, BUTTON_HEIGHT) forImage:@"infoImage.png"];
    homeButton = [self newCustomButton:CGRectMake(0, 0, BUTTON_HEIGHT, BUTTON_HEIGHT) forImage:@"homeImage.png"];
    unitPickerButton = [self newCustomButton:CGRectMake((deviceFrameWidth - BUTTON_HEIGHT) / 2, 0, BUTTON_HEIGHT, BUTTON_HEIGHT) forImage:@"unitImage.png"];
    
    [infoButton  addTarget: self
                    action: @selector(showInfo)
          forControlEvents: UIControlEventTouchDown];
    
    [homeButton  addTarget: self
                    action: @selector(showMenu)
          forControlEvents: UIControlEventTouchDown];
    
    [unitPickerButton  addTarget: self
                          action: @selector(selectUnit)
                forControlEvents: UIControlEventTouchDown];
    
    [self addSubview:infoButton];
    [self addSubview:homeButton];
    [self addSubview:unitPickerButton];
    
}

//For displaying the window that performs dimension calculations
- (void)createDimensionMeasureWindow {
    
    green = [UIImage imageNamed:@"green.png"];
    red = [UIImage imageNamed:@"red.png"];
    orange = [UIImage imageNamed:@"orange.png"];
    
    calibrateButton = [self newButton: CGRectMake((deviceFrameWidth - BUTTON_WIDTH) / 2, deviceFrameHeight - BUTTON_HEIGHT, BUTTON_WIDTH, BUTTON_HEIGHT) forTitle:@"Calibrate"];
    captureButton = [self newCustomButton:CGRectMake((deviceFrameWidth - CAPTURE_BUTTON_HEIGHT) / 2, deviceFrameHeight - CAPTURE_BUTTON_HEIGHT,  CAPTURE_BUTTON_HEIGHT, CAPTURE_BUTTON_HEIGHT) forImage:nil];
    recalibrateButton = [self newButton:CGRectMake((deviceFrameWidth - BUTTON_WIDTH) / 2, 0, BUTTON_WIDTH, BUTTON_HEIGHT) forTitle:@"Recalibrate"];
    
    [calibrateButton addTarget: self
                        action: @selector(calibrate)
              forControlEvents: UIControlEventTouchDown];
    
    [captureButton addTarget: self
                      action: @selector(takePhoto)
            forControlEvents: UIControlEventTouchDown];
    
    [recalibrateButton addTarget: self
                          action: @selector(enableCalibrate)
                forControlEvents: UIControlEventTouchDown];
    
    [self addSubview:calibrateButton];
    [self addSubview:captureButton];
    [self addSubview:recalibrateButton];
    
}

//For displaying the window that performs distance calculations
- (void)createDistanceMeasureWindow {
    
    markPositon1Button = [self newButton:CGRectMake((deviceFrameWidth - BUTTON_WIDTH) / 2, deviceFrameHeight - BUTTON_HEIGHT, BUTTON_WIDTH, BUTTON_HEIGHT) forTitle:@"Mark Position 1"];
    [markPositon1Button addTarget: self
                           action: @selector(markPosition1)
                 forControlEvents: UIControlEventTouchDown];
    
    distanceOutputlabel1 = [self newLabel:CGRectMake(0, BUTTON_HEIGHT, deviceFrameWidth, GUIDE_LABEL_HEIGHT)];
    distanceOutputlabel2 = [self newLabel:CGRectMake(0, BUTTON_HEIGHT + GUIDE_LABEL_HEIGHT, deviceFrameWidth,GUIDE_LABEL_HEIGHT)];
    distanceOutputlabel3 = [self newLabel:CGRectMake(0, BUTTON_HEIGHT + 2 * GUIDE_LABEL_HEIGHT, deviceFrameWidth,GUIDE_LABEL_HEIGHT)];
    
    [distanceOutputlabel1 setHidden:YES];
    
    [self addSubview:markPositon1Button];
    [self addSubview:distanceOutputlabel1];
    [self addSubview:distanceOutputlabel2];
    [self addSubview:distanceOutputlabel3];
    
}

//For displaying the window that performs height calculations
- (void)createHeightMeasureWindow {
    
    
    markBaseButton =[self newButton:CGRectMake((deviceFrameWidth - BUTTON_WIDTH) / 2, deviceFrameHeight - BUTTON_HEIGHT, BUTTON_WIDTH, BUTTON_HEIGHT) forTitle:@"Set Base"];
    
    [markBaseButton addTarget: self
                       action: @selector(markBase)
             forControlEvents: UIControlEventTouchDown];
    
    
    heightOutputLabel = [self newLabel:CGRectMake(0, BUTTON_HEIGHT, deviceFrameWidth, GUIDE_LABEL_HEIGHT)];
    heightOutputLabel.font = [UIFont systemFontOfSize:HEIGHT_OUTPUT_FONT_SIZE1];
    
    [self addSubview:markBaseButton];
    [self addSubview:heightOutputLabel];
    
}

#pragma mark - Label and Button Creation


//Function that creates a label based on the given frame
- (UILabel *)newLabel:(CGRect)frame {
    
    UILabel *label = [[UILabel alloc]initWithFrame:frame];
    
    label.backgroundColor = [UIColor colorWithRed:0
                                            green:0
                                             blue:0
                                            alpha:TRANSPARENT_ALPHA];
    
    label.textAlignment = NSTextAlignmentLeft;
    label.textColor = [UIColor whiteColor];
    label.font=[UIFont systemFontOfSize:HEIGHT_OUTPUT_FONT_SIZE];
    label.numberOfLines = 0;
    label.text = @"";
    [label setHidden:YES];
    
    return label;
    
}

//Function that creates a normal button based on the given frame and title
- (UIButton *)newButton:(CGRect)frame forTitle:(NSString*)title {
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    
    button.frame = frame;
    button.backgroundColor = [UIColor colorWithRed:BACKGROUND_COLOR_RED
                                             green:BACKGROUND_COLOR_GREEN
                                              blue:BACKGROUND_COLOR_BLUE
                                             alpha:FULL_OPAQUE_ALPHA];
    button.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    
    [button setTitle:title
            forState:UIControlStateNormal ];
    [button setTitleColor:[UIColor whiteColor]
                 forState:UIControlStateNormal];
    [button setEnabled:YES];
    [button setHidden:YES];
    [button setUserInteractionEnabled:YES];
    
    return button;
    
}

//Function that creates a normal button based on the given frame and image
- (UIButton *)newCustomButton:(CGRect)frame forImage:(NSString*)imageName {
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = frame;
    
    [button setEnabled:YES];
    [button setHidden:YES];
    
    UIImage *image = [UIImage imageNamed:imageName];
    
    [button setImage:image
            forState:UIControlStateNormal];
    [button setUserInteractionEnabled:YES];
    
    return button;
    
}

#pragma mark - Main Menu Operations

//For displaying the buttons and controls for perfoming height calculations
- (void)startHeightCalculation {
    
    [self hideMenu];
    
    currentMeasuringMode = HEIGHT_MEASURING_MODE;
    nextGuide = HEIGHT_SLIDER_GUIDE;
    [markBaseButton setHidden:NO];
    
    if(showHeightGuide) {
        
        [self showInfo];
        
        nextGuide = MARK_BASE_GUIDE;
        timer = [NSTimer scheduledTimerWithTimeInterval:GUIDE_HIDE_INTERVAL
                                                 target:self selector:@selector(showInfo)
                                               userInfo:nil
                                                repeats:NO];
        
    }
    
}

//For displaying the buttons and controls for perfoming distance calculations
- (void)startDistanceCalculation {
    
    [self hideMenu];
    
    currentMeasuringMode = DISTANCE_MEASURING_MODE;
    nextGuide = HEIGHT_SLIDER_GUIDE;
    [markPositon1Button setHidden:NO];
    
    if(showDistanceGuide) {
        
        [self showInfo];
        
        nextGuide = MARK_POSITION1_GUIDE;
        timer = [NSTimer scheduledTimerWithTimeInterval:GUIDE_HIDE_INTERVAL
                                                 target:self
                                               selector:@selector(showInfo)
                                               userInfo:nil
                                                repeats:NO];
        
    }
    
}

//For displaying the buttons and controls for perfoming dimension calculations
- (void)startDimensionCalculation {
    
    [self hideMenu];
    
    currentMeasuringMode = DIMENSION_MEASURING_MODE;
    nextGuide = HEIGHT_SLIDER_GUIDE;
    [calibrateButton setHidden:NO];
    
    if(showDimensionGuide) {
        
        [self showInfo];
        
        nextGuide = CALIBRATE_GUIDE;
        timer = [NSTimer scheduledTimerWithTimeInterval:GUIDE_HIDE_INTERVAL
                                                 target:self
                                               selector:@selector(showInfo)
                                               userInfo:nil
                                                repeats:NO];
        
    }
    
}

//For hiding the menu
- (void)hideMenu {
    
    [backgroundImageView setHidden:YES];
    
    [measureDimensionButton setHidden:YES];
    [measureDimensionButton setUserInteractionEnabled:NO];
    [measureHeightButton setHidden:YES];
    [measureHeightButton setUserInteractionEnabled:NO];
    [measureDistanceButton setHidden:YES];
    [measureDistanceButton setUserInteractionEnabled:NO];
    
    [homeButton setHidden:NO];
    [infoButton setHidden:NO];
    [sliderValueLabel setHidden:NO];
    [heightSlider setHidden:NO];
    [crossHairView setHidden:NO];
    [unitPickerButton setHidden:NO];
    
    [dimensionInfoButton setHidden:YES];
    [distanceInfoButton setHidden:YES];
    [heightInfoButton setHidden:YES];
    
    sliderValueLabel.alpha = 1.0;
    heightSlider.alpha = 1.0;
    crossHairView.alpha = 1.0;
    
    [self fadeGuides];
    
}

//For showing the menu
- (void)showMenu{
    
    [backgroundImageView setHidden:NO];
    
    [measureDimensionButton setHidden:NO];
    [measureDimensionButton setUserInteractionEnabled:YES];
    [measureHeightButton setHidden:NO];
    [measureHeightButton setUserInteractionEnabled:YES];
    [measureDistanceButton setHidden:NO];
    [measureDistanceButton setUserInteractionEnabled:YES];
    
    [calibrateButton setHidden:YES];
    [markPositon1Button setHidden:YES];
    [recalibrateButton setHidden:YES];
    [markBaseButton setHidden:YES];
    [captureButton setHidden:YES];
    
    [distanceOutputlabel1 setHidden:YES];
    [distanceOutputlabel2 setHidden:YES];
    [distanceOutputlabel3 setHidden:YES];
    
    [heightOutputLabel setHidden:YES];
    [homeButton setHidden:YES];
    [infoButton setHidden:YES];
    [unitPickerButton setHidden:YES];
    
    [sliderValueLabel setHidden:YES];
    [heightSlider setHidden:YES];
    [crossHairView setHidden:YES];
    
    [dimensionInfoButton setHidden:NO];
    [distanceInfoButton setHidden:NO];
    [heightInfoButton setHidden:NO];
    
    [self fadeGuides];
    
}

#pragma mark - Guides and Info Operations

//For showing guides based on the next guides value
- (void)showInfo {
    
    [self fadeGuides];
    switch (nextGuide) {
        case HEIGHT_SLIDER_GUIDE:
            [self heightSliderGuide];
            break;
            
        case CALIBRATE_GUIDE:
            [self calibrateGuide];
            break;
            
        case CAPTURE_GUIDE:
            [self captureGuide];
            break;
            
        case MARK_POSITION1_GUIDE:
            [self markPosition1Guide];
            break;
            
        case DISTANCE_GUIDE:
            [self distanceGuide];
            break;
            
        case MARK_BASE_GUIDE:
            [self markBaseGuide];
            break;
            
        case CALCULATE_HEIGHT_GUIDE:
            [self calculateHeightGuide];
            break;
            
        default:
            break;
            
    }
    
}

//Guide for showing how quick height measure option
- (void)showHeightInfo {
    
    UIImage *infoImage = [UIImage imageNamed:@"heightInfoImage.png"];
    
    infoImageView = [[UIImageView alloc] initWithImage:infoImage];
    infoImageView.frame = CGRectMake(0, (deviceFrameHeight-deviceFrameWidth) / 2, deviceFrameWidth, deviceFrameWidth);
    
    [infoImageView setHidden:NO];
    [self addSubview:infoImageView];
    
    guideBackground  = [[UIView alloc] initWithFrame:CGRectMake(0, (deviceFrameHeight - deviceFrameWidth) / 2, deviceFrameWidth, deviceFrameWidth)];
    guideBackground.backgroundColor = [UIColor clearColor];
    
    [self addSubview:guideBackground];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:GUIDE_CLEAR_INTERVAL
                                             target:self
                                           selector:@selector(fadeGuides)
                                           userInfo:nil
                                            repeats:NO];
    
}

//Guide for showing how distance between objects measure option
- (void)showDistanceInfo {
    
    UIImage *infoImage = [UIImage imageNamed:@"distanceInfoImage.png"];
    
    infoImageView = [[UIImageView alloc] initWithImage:infoImage];
    infoImageView.frame = CGRectMake(0, (deviceFrameHeight - deviceFrameWidth) / 2, deviceFrameWidth, deviceFrameWidth);
    
    [infoImageView setHidden:NO];
    [self addSubview:infoImageView];
    
    guideBackground  = [[UIView alloc] initWithFrame:CGRectMake(0, (deviceFrameHeight - deviceFrameWidth) / 2, deviceFrameWidth, deviceFrameWidth)];
    guideBackground.backgroundColor = [UIColor clearColor];
    
    [self addSubview:guideBackground];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:GUIDE_CLEAR_INTERVAL
                                             target:self
                                           selector:@selector(fadeGuides)
                                           userInfo:nil
                                            repeats:NO];
    
}

//Guide for showing how measure any dimension option works
- (void)showDimensionInfo {
    
    UIImage *infoImage = [UIImage imageNamed:@"dimensionInfoImage.png"];
    
    infoImageView = [[UIImageView alloc] initWithImage:infoImage];
    infoImageView.frame = CGRectMake(0, (deviceFrameHeight-deviceFrameWidth) / 2 , deviceFrameWidth , deviceFrameWidth);
    [infoImageView setHidden:NO];
    
    guideBackground  = [[UIView alloc] initWithFrame:CGRectMake(0, (deviceFrameHeight - deviceFrameWidth) / 2, deviceFrameWidth, deviceFrameWidth)];
    guideBackground.backgroundColor = [UIColor clearColor];
    
    [self addSubview:infoImageView];
    [self addSubview:guideBackground];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:GUIDE_CLEAR_INTERVAL
                                             target:self
                                           selector:@selector(fadeGuides)
                                           userInfo:nil
                                            repeats:NO];
    
}

//Guide for showing how height slider works
- (void)heightSliderGuide {
    
    guideBackground  = [[UIView alloc] initWithFrame:CGRectMake(2 * SLIDER_WIDTH, 0, deviceFrameWidth - 2 * SLIDER_WIDTH, deviceFrameHeight)];
    guideBackground.backgroundColor = [UIColor colorWithRed:GUIDE_BACKGROUND_COLOR_RED
                                                      green:GUIDE_BACKGROUND_COLOR_GREEN
                                                       blue:GUIDE_BACKGROUND_COLOR_BLUE
                                                      alpha:GUIDE_BACKGROUND_ALPHA];
    
    UIImage *guideImage = [UIImage imageNamed:@"sliderGuideImage.png"];
    
    guideImageView = [[UIImageView alloc] initWithImage:guideImage];
    guideImageView.frame = CGRectMake(2 * SLIDER_WIDTH, deviceFrameHeight - deviceFrameWidth, deviceFrameWidth, deviceFrameWidth);
    
    [self addSubview:guideBackground];
    [self addSubview:guideImageView];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:GUIDE_HIDE_INTERVAL
                                             target:self
                                           selector:@selector(fadeGuides)
                                           userInfo:nil
                                            repeats:NO];
    
}

//Guide for showing purpose of calibrate button
- (void)calibrateGuide {
    
    [self showCrosshairAndButtonGuide:@"pointerGuideImage.png"
                            forimage2:@"pointerGuideImageSmall.png"
                            forimage3:@"calibrateGuideImage"
                         fornextGuide:0];
    
}

//Guide for showing purpose of capture button
- (void)captureGuide {
    
    guideBackground  = [[UIView alloc] initWithFrame:CGRectMake(0, INDICATOR_POSITION_OFFSET_Y +BUTTON_HEIGHT, deviceFrameWidth, deviceFrameWidth / 2)];
    guideBackground.backgroundColor = [UIColor colorWithRed:GUIDE_BACKGROUND_COLOR_RED
                                                      green:GUIDE_BACKGROUND_COLOR_GREEN
                                                       blue:GUIDE_BACKGROUND_COLOR_BLUE
                                                      alpha:GUIDE_BACKGROUND_ALPHA];
    
    [self addSubview:guideBackground];
    
    UIImage *guideImage = [UIImage imageNamed:@"indicatorGuide.png"];
    
    guideImageView = [[UIImageView alloc] initWithImage:guideImage];
    guideImageView.frame = CGRectMake(0, INDICATOR_POSITION_OFFSET_Y + BUTTON_HEIGHT, deviceFrameWidth, deviceFrameWidth);
    
    [self addSubview:guideImageView];
    [self showCrosshairAndButtonGuide:nil
                            forimage2:nil
                            forimage3:@"captureGuideImage.png"
                         fornextGuide:0];
    
}

//Guide for showing how to use mark base button
- (void)markBaseGuide {
    
    [self showCrosshairAndButtonGuide:@"pointerGuideImage1.png"
                            forimage2:@"pointerGuideImageSmall1.png"
                            forimage3:@"markbaseGuideImage.png"
                         fornextGuide:0];
    
}

//Guide for showing how to calculate height
- (void)calculateHeightGuide {
    
    [self showCrosshairGuide:@"pointerGuideImage2.png"
                   forimage2:@"pointerGuideImageSmall2"];
    
}

//Guide for showing how mark position1 button works
-( void)markPosition1Guide {
    
    [self showCrosshairAndButtonGuide:@"pointerGuideImage3.png"
                            forimage2:@"pointerGuideImageSmall3.png"
                            forimage3:@"markPosition1GuideImage.png"
                         fornextGuide:0];
    
}

//Guide for showing how to measure distance between two points
- (void)distanceGuide {
    
    [self showCrosshairGuide:@"pointerGuideImage4.png"
                   forimage2:@"pointerGuideImageSmall4"];
    
}

//Function for showing guide images in various devices
- (void)showCrosshairGuide:(NSString*)image1 forimage2:(NSString*)image2 {
    
    int crossHairY = (deviceFrameWidth-CROSS_HAIR_HEIGHT)/2;
    guideBackground  = [[UIView alloc] initWithFrame:CGRectMake(0, crossHairY + CROSS_HAIR_HEIGHT, deviceFrameWidth, deviceFrameHeight - crossHairY - CROSS_HAIR_HEIGHT - BUTTON_HEIGHT)];
    guideBackground.backgroundColor = [UIColor colorWithRed:GUIDE_BACKGROUND_COLOR_RED
                                                      green:GUIDE_BACKGROUND_COLOR_GREEN
                                                       blue:GUIDE_BACKGROUND_COLOR_BLUE
                                                      alpha:GUIDE_BACKGROUND_ALPHA];
    
    [self addSubview:guideBackground];
    
    if(deviceFrameHeight > MAXIMUM_DEVICE_HEIGHT_FOR_TOP_GUIDE) {
        
        UIImage *guideImage = [UIImage imageNamed:image1];
        
        guideImageView = [[UIImageView alloc] initWithImage:guideImage];
        guideImageView.frame = CGRectMake(deviceFrameWidth / 2 - CROSS_HAIR_WIDTH + POINTER_GUIDE_X_OFFSET, crossHairY + CROSS_HAIR_HEIGHT + POINTER_GUIDE_Y_OFFSET, GUIDE_IMAGE_SIZE, GUIDE_IMAGE_SIZE);
        
    }
    
    else {
        
        UIImage *guideImage = [UIImage imageNamed:image2];
        
        guideImageView = [[UIImageView alloc] initWithImage:guideImage];
        guideImageView.frame = CGRectMake(deviceFrameWidth / 2 + POINTER_GUIDE_Y_OFFSET_SMALL_1 - CROSS_HAIR_WIDTH,crossHairY+CROSS_HAIR_HEIGHT+POINTER_GUIDE_Y_OFFSET,GUIDE_IMAGE_SIZE_SMALL, GUIDE_IMAGE_SIZE_SMALL);
        
    }
    
    [self addSubview:guideImageView];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:GUIDE_CLEAR_INTERVAL
                                             target:self
                                           selector:@selector(fadeGuides)
                                           userInfo:nil
                                            repeats:NO];
    
}

//Function for showing guide images for crosshair and associated buttons
- (void)showCrosshairAndButtonGuide:(NSString*)image1 forimage2:(NSString*)image2 forimage3:(NSString*)image3 fornextGuide:(int)nextGuideId {
     
    if(deviceFrameHeight > MAXIMUM_DEVICE_HEIGHT_FOR_TOP_GUIDE) {
        
        [self addGuideForiPadWithImage1Name:image1 andImage2Name:image3];
        
    }
    
    else {
        
        [self addGuideForiPhoneWithImage1Name:image2
                                andImage2Name:image3];
        
    }
    
    if(image3 != nil) {
        
        UIImage *guideImage = [UIImage imageNamed:image3];
        
        guideImageView1 = [[UIImageView alloc] initWithImage:guideImage];
        guideImageView1.frame = CGRectMake(deviceFrameWidth / 2 - CALIBERATE_GUIDE_X_OFFSET, deviceFrameHeight - GUIDE_IMAGE_SIZE / 4 - BUTTON_HEIGHT, GUIDE_IMAGE_SIZE, GUIDE_IMAGE_SIZE);
        
        [self addSubview:guideImageView1];
        
    }
    
    if(nextGuideId > 0)
        nextGuide = nextGuideId;
    
    timer = [NSTimer scheduledTimerWithTimeInterval:GUIDE_CLEAR_INTERVAL
                                             target:self
                                           selector:@selector(fadeGuides)
                                           userInfo:nil
                                            repeats:NO];
    
}

//Function for showing guide images for crosshair and associated buttons in iPad devices
- (void)addGuideForiPadWithImage1Name:(NSString*)image1 andImage2Name:(NSString*)image2 {
    
    
    int crossHairY = (deviceFrameWidth-CROSS_HAIR_HEIGHT)/2;
    
    if(image1 != nil) {
        
        guideBackground = [[UIView alloc] initWithFrame:CGRectMake(0, crossHairY + CROSS_HAIR_HEIGHT, deviceFrameWidth, deviceFrameHeight - crossHairY - CROSS_HAIR_HEIGHT - BUTTON_HEIGHT)];
        
        guideBackground.backgroundColor = [UIColor colorWithRed:GUIDE_BACKGROUND_COLOR_RED
                                                          green:GUIDE_BACKGROUND_COLOR_GREEN
                                                           blue:GUIDE_BACKGROUND_COLOR_BLUE
                                                          alpha:GUIDE_BACKGROUND_ALPHA];
        
        [self addSubview:guideBackground];
        
        UIImage *guideImage = [UIImage imageNamed:image1];
        
        guideImageView = [[UIImageView alloc] initWithImage:guideImage];
        guideImageView.frame = CGRectMake(deviceFrameWidth / 2 - CROSS_HAIR_WIDTH + POINTER_GUIDE_X_OFFSET, crossHairY + CROSS_HAIR_HEIGHT + POINTER_GUIDE_Y_OFFSET, GUIDE_IMAGE_SIZE, GUIDE_IMAGE_SIZE);
        
        [self addSubview:guideImageView];
        
    }
    else if(image2 != nil) {
        
        guideBackground1 = [[UIView alloc] initWithFrame:CGRectMake(0, crossHairY + CALIBERATE_GUIDE_Y_OFFSET, deviceFrameWidth, deviceFrameHeight - crossHairY - BUTTON_HEIGHT - CALIBERATE_GUIDE_Y_OFFSET)];
        
        guideBackground1.backgroundColor = [UIColor colorWithRed:GUIDE_BACKGROUND_COLOR_RED
                                                           green:GUIDE_BACKGROUND_COLOR_GREEN
                                                            blue:GUIDE_BACKGROUND_COLOR_BLUE
                                                           alpha:GUIDE_BACKGROUND_ALPHA];
        
        [self addSubview:guideBackground1];
        
    }
    
    
}

//Function for showing guide images for crosshair and associated buttons in iPhone devices
- (void)addGuideForiPhoneWithImage1Name:(NSString*)image1 andImage2Name:(NSString*)image2 {
    
    
    int crossHairY = (deviceFrameWidth-CROSS_HAIR_HEIGHT)/2;
    
    if(image1 != nil) {
        
        guideBackground  = [[UIView alloc] initWithFrame:CGRectMake(0, 0, deviceFrameWidth, crossHairY + POINTER_GUIDE_Y_OFFSET_SMALL)];
        guideBackground.backgroundColor = [UIColor colorWithRed:GUIDE_BACKGROUND_COLOR_RED
                                                          green:GUIDE_BACKGROUND_COLOR_GREEN
                                                           blue:GUIDE_BACKGROUND_COLOR_BLUE
                                                          alpha:GUIDE_BACKGROUND_ALPHA];
        
        [self addSubview:guideBackground];
        
        UIImage *guideImage = [UIImage imageNamed:image2];
        
        guideImageView = [[UIImageView alloc] initWithImage:guideImage];
        guideImageView.frame = CGRectMake(0, - POINTER_GUIDE_Y_OFFSET, GUIDE_IMAGE_SIZE_SMALL, GUIDE_IMAGE_SIZE_SMALL);
        
        [self addSubview:guideImageView];
        
    }
    
    if(image2 != nil) {
        
        guideBackground1 = [[UIView alloc] initWithFrame:CGRectMake(0, crossHairY + CALIBERATE_GUIDE_Y_OFFSET, deviceFrameWidth, deviceFrameHeight - crossHairY - BUTTON_HEIGHT - CALIBERATE_GUIDE_Y_OFFSET)];
        
        guideBackground1.backgroundColor = [UIColor colorWithRed:GUIDE_BACKGROUND_COLOR_RED
                                                           green:GUIDE_BACKGROUND_COLOR_GREEN
                                                            blue:GUIDE_BACKGROUND_COLOR_BLUE
                                                           alpha:GUIDE_BACKGROUND_ALPHA];
        
        [self addSubview:guideBackground1];
        
    }
    
}

//For fading the guides
- (void)fadeGuides {
    
    [self fadeOutAnimateItem:guideImageView];
    [self fadeOutAnimateItem:guideImageView1];
    [self fadeOutAnimateItem:guideBackground];
    [self fadeOutAnimateItem:guideBackground1];
    [self fadeOutAnimateItem:infoImageView];
    
}

//For showing the guides
- (void)showGuides {
    
    [self fadeInAnimateItem:guideImageView];
    [self fadeInAnimateItem:guideImageView1];
    [self fadeInAnimateItem:guideBackground];
    [self fadeInAnimateItem:guideBackground1];
    
}

#pragma mark - Animations

//For fading out the given item
- (void)fadeOutAnimateItem:(UIView*)UIitem {
    
    [UIView beginAnimations:@"fade" context:nil];
    [UIView setAnimationDuration:ANIMATION_DURATION];
    UIitem.alpha = 0.0;
    [UIView commitAnimations];
    
}

//For fading in the given item
- (void)fadeInAnimateItem:(UIView*)UIitem {
    
    [UIView beginAnimations:@"fade" context:nil];
    [UIView setAnimationDuration:ANIMATION_DURATION];
    UIitem.alpha = FULL_OPAQUE_ALPHA;
    [UIView commitAnimations];
    
}

#pragma mark - Distance Calculation Functions

//For selecting the unit scale
- (void) selectUnit {
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:@"Unit Picker"
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:@"Centimeter", @"Meter", @"Foot", @"Inch", nil];
    
    [actionSheet showInView:self];
    
}

//For changing the camera height using the slider
- (void)adjustHeight {
    
    NSString *txt;
    float cameraHeightValue;
    
    cameraHeight = heightSlider.value;
    cameraHeightValue = cameraHeight * [MEASUREMENT_FACTORS[currentUnit] floatValue];
    
    switch (currentUnit) {
            
        case 0:txt = [NSString stringWithFormat:@"%.0f cm", cameraHeightValue];
               break;
        case 1:txt = [NSString stringWithFormat:@"%.2f m", cameraHeightValue];
               break;
        case 2:txt = [NSString stringWithFormat:@"%.2f ft", cameraHeightValue];
               break;
        case 3:txt = [NSString stringWithFormat:@"%.1f inch", cameraHeightValue];
               break;
        default:txt = @"Error";
                break;
            
    }
    
    CGRect frame = sliderValueLabel.frame;
    frame.origin.y = [self sliderThumbPosition:heightSlider];
    
    sliderValueLabel.frame = frame;
    sliderValueLabel.text = txt;
    
    switch (currentMeasuringMode) {
            
        case HEIGHT_MEASURING_MODE:
            nextGuide = MARK_BASE_GUIDE;
            break;
            
        case DISTANCE_MEASURING_MODE:
            nextGuide = MARK_POSITION1_GUIDE;
            break;
            
        case DIMENSION_MEASURING_MODE:
            nextGuide = CALIBRATE_GUIDE;
            break;
            
        default:
            break;
            
    }
    
    [self fadeGuides];
    
}

//For positioning the slider output value
- (float)sliderThumbPosition:(UISlider *)slider {
    
    float sliderRange, sliderStartPosition, sliderPixelHeight, labelPosition;
    float correctionFactor = SLIDER_VALUE_POSTION_CORRECTION_OFFSET - (slider.value / SLIDER_VALUE_POSTION_CORRECTION_FACTOR);
    
    sliderRange = slider.frame.size.height - slider.currentThumbImage.size.height;
    sliderStartPosition = slider.frame.origin.y + (slider.currentThumbImage.size.height / 2.0);
    sliderPixelHeight = (((slider.value - slider.minimumValue) / (slider.maximumValue - slider.minimumValue )) * sliderRange) + sliderStartPosition;
    labelPosition = deviceFrameHeight - sliderPixelHeight + correctionFactor;
    
    return labelPosition;
    
}

//For finding the distance to the object
- (void)calibrate {
    
    float angle;
    CMAttitude *attitude;
    CMDeviceMotion *motion;
    
    motion = motionManager.deviceMotion;
    attitude = motion.attitude;
    angle = attitude.pitch;
    if(angle < 0)
        angle = - angle;
    
    distance = cameraHeight * tan(angle);
    
    [calibrateButton setHidden:YES];
    [unitPickerButton setHidden:YES];
    [captureButton setHidden:NO];
    [recalibrateButton setHidden:NO];
    
    [self fadeInAnimateItem:recalibrateButton];
    [self fadeOutAnimateItem:crossHairView];
    [self fadeOutAnimateItem:heightSlider];
    [self fadeOutAnimateItem:sliderValueLabel];
    
    nextGuide = CAPTURE_GUIDE;
    
    [self fadeGuides];
    
    [self.viewController setTypeAsCamera];
    if(showDimensionGuide) {
        
        guideBackground1.alpha = 0;
        guideImageView1.alpha = 0;
        guideBackground.alpha = 0;
        guideImageView.alpha = 0;
        
        [self showInfo];
        showDistanceGuide = NO;
        
    }
    
    timer = [NSTimer scheduledTimerWithTimeInterval:HEIGHT_UPDATE_INTERVAL
                                             target:self
                                           selector:@selector(showIndicator)
                                           userInfo:nil
                                            repeats:YES];
    
}

//For showing the accuracy indicator
- (void)showIndicator {
    
    float angle;
    CMAttitude *attitude;
    CMDeviceMotion *motion;
    
    motion = motionManager.deviceMotion;
    attitude = motion.attitude;
    angle = degrees(attitude.pitch);
    
    if(angle > 80) {
        
        [captureButton setImage:green
                       forState:UIControlStateNormal];
        
    }
    else if(angle > 50) {
        
        [captureButton setImage:orange
                       forState:UIControlStateNormal];
        
    }
    else {
        
        [captureButton setImage:red
                       forState:UIControlStateNormal];
    }
    
    
}

//For resetting the base
- (void)enableCalibrate {
    
    [calibrateButton setHidden:NO];
    [unitPickerButton setHidden:NO];
    [captureButton setHidden:YES];
    [recalibrateButton setHidden:YES];
    
    [self fadeInAnimateItem:crossHairView];
    [self fadeInAnimateItem:heightSlider];
    [self fadeInAnimateItem:sliderValueLabel];
    
    nextGuide=CALIBRATE_GUIDE;
    [self fadeGuides];
    [self.viewController setTypeAsVideo];
    
}

//For capturing the photo
- (void)takePhoto {
    [self.viewController callBack:distance];
    [self fadeGuides];
    
}

//For finding the base of the object
- (void)markBase {
    
    CMAttitude *attitude;
    CMDeviceMotion *motion;
    float angleOfTilt;
    
    motion = motionManager.deviceMotion;
    attitude = motion.attitude;
    angleOfTilt = attitude.pitch;
    
    yawChange = NO;
    initialPosition = POSITIVE_YAW;
    
    if(attitude.yaw < 0)
        initialPosition = NEGATIVE_YAW;
    
    if(angleOfTilt < 0)
        angleOfTilt = - angleOfTilt;
    
    previousPosition = initialPosition;
    distance = cameraHeight * tan(angleOfTilt);
    
    [heightOutputLabel setHidden:NO];
    objectHigherThanCamera=NO;
    
    timer = [NSTimer scheduledTimerWithTimeInterval:HEIGHT_UPDATE_INTERVAL
                                             target:self
                                           selector:@selector(calculateHeight)
                                           userInfo:nil
                                            repeats:YES];
    
    nextGuide=CALCULATE_HEIGHT_GUIDE;
    
    if(showHeightGuide) {
        
        guideBackground1.alpha = 0;
        guideImageView1.alpha = 0;
        guideBackground.alpha = 0;
        guideImageView.alpha = 0;
        
        [self showInfo];
        
        showHeightGuide = NO;
        
    }
    
}

//For calculating the height of objects
- (void)calculateHeight {
    
    float angleOfTilt, height;
    CMAttitude *attitude;
    CMDeviceMotion *motion;
    NSString *txt;
    
    motion = motionManager.deviceMotion;
    attitude = motion.attitude;
    angleOfTilt = attitude.pitch;
    
    finalPostion = POSITIVE_YAW;
    
    if(attitude.yaw < 0)
        finalPostion = NEGATIVE_YAW;
    
    if((previousPosition != finalPostion) && ((degrees(M_PI_2) - degrees(angleOfTilt)) > YAW_CHANGE_CUTOFF_ANGLE)) {
        
        if(initialPosition != previousPosition)
            initialPosition = previousPosition;
        
        else
            initialPosition = finalPostion;
        
    }
    
    previousPosition = finalPostion;
    
    if(angleOfTilt < 0)
        angleOfTilt = - angleOfTilt;
    
    if(initialPosition == finalPostion) {
        
        height = cameraHeight - (distance / tan(angleOfTilt));
        
    }
    else {
        
        angleOfTilt = (M_PI_2) - angleOfTilt;
        height = cameraHeight + (distance * tan(angleOfTilt));
        
    }
    
    if(height > 0) {
        
        height = height * [MEASUREMENT_FACTORS[currentUnit] floatValue];
        
        switch (currentUnit) {
            case 0:txt = [NSString stringWithFormat:@"Height  : %.1f cm", height];
                   break;
            case 1:txt = [NSString stringWithFormat:@"Height  : %.2f m", height];
                   break;
            case 2:txt = [NSString stringWithFormat:@"Height  : %.2f ft", height];
                   break;
            case 3:txt = [NSString stringWithFormat:@"Height  : %.1f inch", height];
                   break;
            default:txt = @"Error";
                    break;
                
        }
        
    }
    else {
        
        txt = @"Move from base to top";
        
    }
    
    heightOutputLabel.text = txt;
    
}

//For marking the position 1 on the ground
- (void)markPosition1 {
    
    CMAttitude *attitude;
    CMDeviceMotion *motion;
    float angleOfTilt;
    
    motion = motionManager.deviceMotion;
    attitude = motion.attitude;
    angleOfTilt = attitude.pitch;
 
    if(angleOfTilt < 0)
        angleOfTilt = - angleOfTilt;
    distance = cameraHeight * tan(angleOfTilt);
    
    
     
    timer = [NSTimer scheduledTimerWithTimeInterval:DISTANCE_UPDATE_INTERVAL
                                             target:self
                                           selector:@selector(calculateDistance)
                                           userInfo:nil
                                            repeats:YES];
    
    [distanceOutputlabel1 setHidden:NO];
    [distanceOutputlabel2 setHidden:NO];
    [distanceOutputlabel3 setHidden:NO];
    
    nextGuide = DISTANCE_GUIDE;
    [self fadeGuides];
    
    if(showDistanceGuide) {
        
        guideBackground1.alpha = 0;
        guideImageView1.alpha = 0;
        guideBackground.alpha = 0;
        guideImageView.alpha = 0;
        
        timer = [NSTimer scheduledTimerWithTimeInterval:GUIDE_UPDATE_INTERVAL2
                                                 target:self
                                               selector:@selector(showInfo)
                                               userInfo:nil
                                                repeats:NO];
        
        showDistanceGuide = NO;
        
    }
    
}

//For calculating the distance between two objects
- (void)calculateDistance {
    
    CMAttitude *attitude;
    CMDeviceMotion *motion;
    NSString *txt,*unit;
    float angleOfTilt, distanceToPosition1, distanceToPosition2, distanceBetweenPoints;
    
    motion = motionManager.deviceMotion;
    attitude = motion.attitude;
    angleOfTilt = attitude.pitch;
    
    if(angleOfTilt < 0)
        angleOfTilt = - angleOfTilt;
    
    distanceToPosition2 = cameraHeight * tan(angleOfTilt);
    distanceBetweenPoints = fabsf(distanceToPosition2 - distance);
    
    switch (currentUnit) {
            
        case 0:unit = @"cm";
               break;
        case 1:unit = @"m";
               break;
        case 2:unit = @"ft";
               break;
        case 3:unit = @"inch";
               break;
        default:txt = @"Error";
                break;
            
    }
    
    distanceToPosition1 = distance * [MEASUREMENT_FACTORS[currentUnit] floatValue];
    txt = [NSString stringWithFormat:@"Distance To Position 2     : %.1f ", distanceToPosition1];
    distanceOutputlabel1.text = txt;
    
    distanceToPosition2 = distanceToPosition2 * [MEASUREMENT_FACTORS[currentUnit] floatValue];
    txt = [NSString stringWithFormat:@"Distance To Position 2     : %.1f %@", distanceToPosition2, unit];
    distanceOutputlabel2.text = txt;
    
    distanceBetweenPoints = distanceBetweenPoints * [MEASUREMENT_FACTORS[currentUnit] floatValue];
    txt = [NSString stringWithFormat:@"Distance Between Them : %.1f %@", distanceBetweenPoints, unit];
    distanceOutputlabel3.text = txt;
    
}

#pragma mark -

- (BOOL)shouldAutorotate {
    
    return NO;
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [self fadeGuides];
    
}

#pragma mark - UIActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if(buttonIndex >= MEASUREMENT_UNITS.count) {
        
        return;
        
    }
    
    currentUnit = (int)buttonIndex;
    [self adjustHeight];
    
}




@end
