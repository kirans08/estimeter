//
//  oV.m
//  OverlayView
//
//  Created by user on 21/04/15.
//  Copyright (c) 2015 user. All rights reserved.
//

#import "CameraOverlay.h"
#import "Constants.h"

@implementation CameraOverlay

float distance,cameraHeight,deviceFrameWidth,deviceFrameHeight;
NSDictionary *crossHairPositionForDeviceHeight;
int initialPosition,finalPostion,previousPosition,nextGuide,currentMeasuringMode,currentUnit;
bool objectHigherThanCamera,showHeightGuide,showDistanceGuide,showDimensionGuide,firstRun,yawChange;
UIImageView *crossHairView,*infoImageView;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame])
    {
        float crossHairX,crossHairY,sliderHeight;
        BOOL multiRun,firstRun=NO;
        showDimensionGuide=NO;
        showDistanceGuide=NO;
        showHeightGuide=NO;
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        cameraHeight=INITAL_CAMERA_HEIGHT;
        crossHairPositionForDeviceHeight = [[NSDictionary alloc] initWithObjectsAndKeys:@"185", @"480",@"205",@"736",@"420",@"1024",@"130",@"568",nil];

        motionManager = [[CMMotionManager alloc]init];
        motionManager.deviceMotionUpdateInterval = MOTION_UPDATE_INTERVAL;
        [motionManager startGyroUpdates];
        [motionManager startDeviceMotionUpdates];
        [motionManager startAccelerometerUpdates];
        
        multiRun = [[NSUserDefaults standardUserDefaults] boolForKey:@"isRunMoreThanOnce"];
        if(!multiRun){
            firstRun=YES;
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isRunMoreThanOnce"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
        }
        if(firstRun)
        {
            showDimensionGuide=YES;
            showDistanceGuide=YES;
            showHeightGuide=YES;
        }
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        deviceFrameWidth = screenRect.size.width;
        deviceFrameHeight = screenRect.size.height;
        
        CGAffineTransform rotateLeft = CGAffineTransformMakeRotation(-M_PI_2);
        sliderHeight=0-(deviceFrameHeight-SLIDER_HEIGHT_OFFSET)/2;
        
        UIImage *sliderThumbImage = [[UIImage imageNamed: @"slider.png"] stretchableImageWithLeftCapWidth: SLIDER_IMAGE_WIDTH topCapHeight: 0];
        UIImage *sliderTrackImage = [[UIImage imageNamed: @"trans.png"] stretchableImageWithLeftCapWidth: SLIDER_IMAGE_WIDTH topCapHeight: 0];
        
        
        crossHairX=(deviceFrameWidth-CROSS_HAIR_WIDTH)/2;
        crossHairY=[[crossHairPositionForDeviceHeight objectForKey:[NSString stringWithFormat:@"%d",(int)deviceFrameHeight]] floatValue];
        UIImage *crossHair = [UIImage imageNamed:@"crossHairImage.png"];
        crossHairView = [[UIImageView alloc] initWithImage:crossHair];
        crossHairView.frame = CGRectMake(crossHairX, crossHairY, CROSS_HAIR_WIDTH, CROSS_HAIR_HEIGHT);
        [crossHairView setHidden:YES];
        [self addSubview:crossHairView];
        
        
        heightSlider = [[UISlider alloc] initWithFrame:frame];
        heightSlider.frame=CGRectMake(sliderHeight, SLIDER_ORIGIN_OFFSET_Y_1+((deviceFrameHeight-SLIDER_CLEARANCE_2)/2), deviceFrameHeight-SLIDER_CLEARANCE_1, SLIDER_WIDTH);
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
        [self addSubview:heightSlider];
        
        
        sliderValueLabel= [[UILabel alloc] initWithFrame:CGRectMake(0, [self sliderThumbPosition:heightSlider], SLIDER_VALUE_WIDTH, SLIDER_VALUE_HEIGHT)];
        sliderValueLabel.textAlignment = NSTextAlignmentCenter;
        sliderValueLabel.textColor = [UIColor whiteColor];
        sliderValueLabel.text = @"130cm";
        sliderValueLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:TRANSPARENT_ALPHA];
        [sliderValueLabel setHidden:YES];
        [self addSubview:sliderValueLabel];
        
        
        
        calibrateButton = [UIButton buttonWithType:UIButtonTypeSystem];
        calibrateButton.frame = CGRectMake((deviceFrameWidth-BUTTON_WIDTH)/2,deviceFrameHeight-BUTTON_HEIGHT, BUTTON_WIDTH , BUTTON_HEIGHT);
        calibrateButton.backgroundColor=[UIColor colorWithRed:BACKGROUND_COLOR_RED green:BACKGROUND_COLOR_GREEN blue:BACKGROUND_COLOR_BLUE alpha:FULL_OPAQUE_ALPHA];
        calibrateButton.layer.cornerRadius=BUTTON_CORNER_RADIUS;
        [calibrateButton setTitle:@"Calibrate" forState:UIControlStateNormal ];
        [calibrateButton setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        [calibrateButton setEnabled:YES];
        [calibrateButton setHidden:YES];
        [calibrateButton setUserInteractionEnabled:YES];
        [calibrateButton addTarget: self action: @selector(calibrate) forControlEvents: UIControlEventTouchDown];
        [self addSubview:calibrateButton];
        
        
        captureButton = [UIButton buttonWithType:UIButtonTypeSystem];
        captureButton.frame = CGRectMake((deviceFrameWidth-BUTTON_WIDTH)/2,deviceFrameHeight-BUTTON_HEIGHT, BUTTON_WIDTH , BUTTON_HEIGHT);
        captureButton.backgroundColor=[UIColor colorWithRed:BACKGROUND_COLOR_RED green:BACKGROUND_COLOR_GREEN blue:BACKGROUND_COLOR_BLUE alpha:FULL_OPAQUE_ALPHA];
        captureButton.layer.cornerRadius=BUTTON_CORNER_RADIUS;
        [captureButton setTitle:@"Take Photo" forState:UIControlStateNormal ];
        [captureButton setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        [captureButton setEnabled:YES];
        [captureButton setHidden:YES];
        [captureButton setUserInteractionEnabled:YES];
        [captureButton addTarget: self action: @selector(takePhoto) forControlEvents: UIControlEventTouchDown];
        [self addSubview:captureButton];
        
        //        t = [[UILabel alloc] initWithFrame:CGRectMake(150,235, 20,20)];
        //        t.textAlignment = NSTextAlignmentCenter;
        //        t.textColor = [UIColor blackColor];
        //        t.numberOfLines = 0;
        //        t.text = @".";
        //        [self addSubview:t];
        
        
        markBaseButton = [UIButton buttonWithType:UIButtonTypeSystem];
        markBaseButton.frame = CGRectMake((deviceFrameWidth-BUTTON_WIDTH)/2,deviceFrameHeight-BUTTON_HEIGHT, BUTTON_WIDTH , BUTTON_HEIGHT);
        markBaseButton.backgroundColor=[UIColor colorWithRed:BACKGROUND_COLOR_RED green:BACKGROUND_COLOR_GREEN blue:BACKGROUND_COLOR_BLUE alpha:FULL_OPAQUE_ALPHA];
        markBaseButton.layer.cornerRadius=BUTTON_CORNER_RADIUS;
        [markBaseButton setTitle:@"Set Base" forState:UIControlStateNormal ];
        [markBaseButton setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        [markBaseButton setEnabled:YES];
        [markBaseButton setHidden:YES];
        [markBaseButton setUserInteractionEnabled:YES];
        [markBaseButton addTarget: self action: @selector(markBase) forControlEvents: UIControlEventTouchDown];
        [self addSubview:markBaseButton];
        
        
        
        heightOutputLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, BUTTON_HEIGHT, deviceFrameWidth, GUIDE_LABEL_HEIGHT)];
        heightOutputLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:TRANSPARENT_ALPHA];
        heightOutputLabel.textAlignment = NSTextAlignmentLeft;
        heightOutputLabel.textColor = [UIColor whiteColor];
        heightOutputLabel.font=[UIFont systemFontOfSize:HEIGHT_OUTPUT_FONT_SIZE];
        heightOutputLabel.font=[heightOutputLabel.font fontWithSize:30];
        heightOutputLabel.text = @"";
        [heightOutputLabel setHidden:YES];
        [self addSubview:heightOutputLabel];
        
        
        
        
        
        
        
        
        
        UIImage *backgroundImage = [UIImage imageNamed:@"backgroundImage.png"];
        backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
        backgroundImageView.alpha=0.75;
        backgroundImageView.frame = CGRectMake(0, 0, deviceFrameWidth, deviceFrameHeight);
        [self addSubview:backgroundImageView];
        
        
        
        measureHeightButton=[UIButton buttonWithType:UIButtonTypeSystem];
        measureHeightButton.frame = CGRectMake((deviceFrameWidth-BUTTON_POSITION_FACTOR*BUTTON_WIDTH)/2,deviceFrameHeight/2-BUTTON_HEIGHT*2, 2*BUTTON_WIDTH , BUTTON_HEIGHT);
        measureHeightButton.backgroundColor=[UIColor colorWithRed:BACKGROUND_COLOR_RED green:BACKGROUND_COLOR_GREEN blue:BACKGROUND_COLOR_BLUE alpha:FULL_OPAQUE_ALPHA];
        measureHeightButton.layer.cornerRadius=BUTTON_CORNER_RADIUS;
        [measureHeightButton setTitle:@"Quick Height Measure" forState:UIControlStateNormal ];
        [measureHeightButton setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
       

        [measureHeightButton  addTarget: self action: @selector(startHeightCalculation) forControlEvents: UIControlEventTouchDown];
        [self addSubview:measureHeightButton];
        
        
        
        heightInfoButton=[UIButton buttonWithType:UIButtonTypeCustom];
        heightInfoButton.frame = CGRectMake((deviceFrameWidth-INFO_BUTTON_POSITION_FACTOR*BUTTON_WIDTH)/2+BUTTON_WIDTH,deviceFrameHeight/2-BUTTON_HEIGHT*2, BUTTON_HEIGHT , BUTTON_HEIGHT);
        UIImage *infoImageSmall = [UIImage imageNamed:@"infoImage.png"];
        [heightInfoButton setImage:infoImageSmall forState:UIControlStateNormal];

        
        
        [heightInfoButton  addTarget: self action: @selector(showHeightInfo) forControlEvents: UIControlEventTouchDown];
        [self addSubview:heightInfoButton];
        
        
        
        
        measureDistanceButton=[UIButton buttonWithType:UIButtonTypeSystem];
        measureDistanceButton.frame = CGRectMake((deviceFrameWidth-BUTTON_POSITION_FACTOR*BUTTON_WIDTH)/2,deviceFrameHeight/2, 2*BUTTON_WIDTH , BUTTON_HEIGHT);
        measureDistanceButton.backgroundColor=[UIColor colorWithRed:BACKGROUND_COLOR_RED green:BACKGROUND_COLOR_GREEN blue:BACKGROUND_COLOR_BLUE alpha:FULL_OPAQUE_ALPHA];
        measureDistanceButton.layer.cornerRadius=BUTTON_CORNER_RADIUS;
        [measureDistanceButton setTitle:@"Distance Between objects" forState:UIControlStateNormal ];
        [measureDistanceButton setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        [measureDistanceButton  addTarget: self action: @selector(startDistanceCalculation) forControlEvents: UIControlEventTouchDown];
        [self addSubview:measureDistanceButton];
        
        
        
        
        distanceInfoButton=[UIButton buttonWithType:UIButtonTypeCustom];
        distanceInfoButton.frame = CGRectMake((deviceFrameWidth-INFO_BUTTON_POSITION_FACTOR*BUTTON_WIDTH)/2+BUTTON_WIDTH,deviceFrameHeight/2 , BUTTON_HEIGHT,BUTTON_HEIGHT);
        [distanceInfoButton setImage:infoImageSmall forState:UIControlStateNormal];
        
        
        
        [distanceInfoButton  addTarget: self action: @selector(showDistanceInfo) forControlEvents: UIControlEventTouchDown];
        [self addSubview:distanceInfoButton];
        
        
        
        
        
        measureDimensionButton=[UIButton buttonWithType:UIButtonTypeSystem];
        measureDimensionButton.frame = CGRectMake((deviceFrameWidth-BUTTON_POSITION_FACTOR*BUTTON_WIDTH)/2,deviceFrameHeight/2+BUTTON_HEIGHT*2, 2*BUTTON_WIDTH , BUTTON_HEIGHT);
        measureDimensionButton.backgroundColor=[UIColor colorWithRed:BACKGROUND_COLOR_RED green:BACKGROUND_COLOR_GREEN blue:BACKGROUND_COLOR_BLUE alpha:FULL_OPAQUE_ALPHA];
        measureDimensionButton.layer.cornerRadius=BUTTON_CORNER_RADIUS;
        [measureDimensionButton setTitle:@"Measure Any Dimension" forState:UIControlStateNormal ];
        [measureDimensionButton setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        [measureDimensionButton  addTarget: self action: @selector(startDimensionCalculation) forControlEvents: UIControlEventTouchDown];
        [self addSubview:measureDimensionButton];
        
        
        
        
        
        dimensionInfoButton=[UIButton buttonWithType:UIButtonTypeCustom];
        dimensionInfoButton.frame = CGRectMake((deviceFrameWidth-INFO_BUTTON_POSITION_FACTOR*BUTTON_WIDTH)/2+BUTTON_WIDTH,deviceFrameHeight/2+BUTTON_HEIGHT*2 , BUTTON_HEIGHT,BUTTON_HEIGHT);
        [dimensionInfoButton setImage:infoImageSmall forState:UIControlStateNormal];
        
        
        
        [dimensionInfoButton  addTarget: self action: @selector(showDimensionInfo) forControlEvents: UIControlEventTouchDown];
        [self addSubview:dimensionInfoButton];
        
        
        
        
        
        
        
        
        
        
        
        infoButton=[UIButton buttonWithType:UIButtonTypeCustom];
        infoButton.frame = CGRectMake(deviceFrameWidth-BUTTON_HEIGHT,0,BUTTON_HEIGHT,BUTTON_HEIGHT);
        infoButton.layer.cornerRadius=BUTTON_CORNER_RADIUS;
        [infoButton setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        [infoButton  addTarget: self action: @selector(showInfo) forControlEvents: UIControlEventTouchDown];
        UIImage *infoImage = [UIImage imageNamed:@"infoImage.png"];
        [infoButton setImage:infoImage forState:UIControlStateNormal];
        [infoButton setHidden:YES];
        [self addSubview:infoButton];
        
        
        homeButton=[UIButton buttonWithType:UIButtonTypeCustom];
        homeButton.frame = CGRectMake(0,0,BUTTON_HEIGHT,BUTTON_HEIGHT);
        homeButton.layer.cornerRadius=BUTTON_CORNER_RADIUS;
        [homeButton setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        [homeButton  addTarget: self action: @selector(showMenu) forControlEvents: UIControlEventTouchDown];
        UIImage *homeImage = [UIImage imageNamed:@"homeImage.png"];
        [homeButton setImage:homeImage forState:UIControlStateNormal];
        [homeButton setHidden:YES];
        [self addSubview:homeButton];
        
        unitPickerButton=[UIButton buttonWithType:UIButtonTypeCustom];
        unitPickerButton.frame = CGRectMake((deviceFrameWidth-BUTTON_HEIGHT)/2,0,BUTTON_HEIGHT,BUTTON_HEIGHT);
        unitPickerButton.layer.cornerRadius=BUTTON_CORNER_RADIUS;
        [unitPickerButton setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        [unitPickerButton  addTarget: self action: @selector(selectUnit) forControlEvents: UIControlEventTouchDown];
        UIImage *unitImage = [UIImage imageNamed:@"unitImage.png"];
        [unitPickerButton setImage:unitImage forState:UIControlStateNormal];
        [unitPickerButton setHidden:YES];
        [self addSubview:unitPickerButton];
        
        recalibrateButton = [UIButton buttonWithType:UIButtonTypeSystem];
        recalibrateButton.frame = CGRectMake((deviceFrameWidth-BUTTON_WIDTH)/2,0, BUTTON_WIDTH , BUTTON_HEIGHT);
        recalibrateButton.backgroundColor=[UIColor colorWithRed:BACKGROUND_COLOR_RED green:BACKGROUND_COLOR_GREEN blue:BACKGROUND_COLOR_BLUE alpha:FULL_OPAQUE_ALPHA];
        recalibrateButton.layer.cornerRadius=BUTTON_CORNER_RADIUS;
        [recalibrateButton setTitle:@"Recalibrate" forState:UIControlStateNormal ];
        [recalibrateButton setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        [recalibrateButton setEnabled:YES];
        [recalibrateButton setHidden:YES];
        [recalibrateButton setUserInteractionEnabled:YES];
        [recalibrateButton addTarget: self action: @selector(enableCalibrate) forControlEvents: UIControlEventTouchDown];
        [self addSubview:recalibrateButton];
        
        
        
        
        
        
        markPositon1Button = [UIButton buttonWithType:UIButtonTypeSystem];
        markPositon1Button.frame = CGRectMake((deviceFrameWidth-BUTTON_WIDTH)/2,deviceFrameHeight-BUTTON_HEIGHT, BUTTON_WIDTH , BUTTON_HEIGHT);
        markPositon1Button.backgroundColor=[UIColor colorWithRed:BACKGROUND_COLOR_RED green:BACKGROUND_COLOR_GREEN blue:BACKGROUND_COLOR_BLUE alpha:FULL_OPAQUE_ALPHA];
        markPositon1Button.layer.cornerRadius=BUTTON_CORNER_RADIUS;
        [markPositon1Button setTitle:@"Mark Position 1" forState:UIControlStateNormal ];
        [markPositon1Button setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        [markPositon1Button setEnabled:YES];
        [markPositon1Button setHidden:YES];
        [markPositon1Button setUserInteractionEnabled:YES];
        [markPositon1Button addTarget: self action: @selector(markPosition1) forControlEvents: UIControlEventTouchDown];
        [self addSubview:markPositon1Button];
        
        
        
        
        
        
        
        distanceOutputlabel1 = [[UILabel alloc] initWithFrame:CGRectMake(0, BUTTON_HEIGHT, deviceFrameWidth, GUIDE_LABEL_HEIGHT)];
        distanceOutputlabel1.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:TRANSPARENT_ALPHA];
        distanceOutputlabel1.textAlignment = NSTextAlignmentLeft;
        distanceOutputlabel1.textColor = [UIColor whiteColor];
        distanceOutputlabel1.font=[UIFont systemFontOfSize:HEIGHT_OUTPUT_FONT_SIZE];
        distanceOutputlabel1.numberOfLines = 0;
        distanceOutputlabel1.text = @"";
        [distanceOutputlabel1 setHidden:YES];
        [self addSubview:distanceOutputlabel1];
        
        distanceOutputlabel2 = [[UILabel alloc] initWithFrame:CGRectMake(0, BUTTON_HEIGHT+GUIDE_LABEL_HEIGHT, deviceFrameWidth, GUIDE_LABEL_HEIGHT)];
        distanceOutputlabel2.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:TRANSPARENT_ALPHA];
        distanceOutputlabel2.textAlignment = NSTextAlignmentLeft;
        distanceOutputlabel2.textColor = [UIColor whiteColor];
        distanceOutputlabel2.font=[UIFont systemFontOfSize:HEIGHT_OUTPUT_FONT_SIZE];
        distanceOutputlabel2.numberOfLines = 0;
        distanceOutputlabel2.text = @"";
        [distanceOutputlabel2 setHidden:YES];
        [self addSubview:distanceOutputlabel2];
        
        distanceOutputlabel3 = [[UILabel alloc] initWithFrame:CGRectMake(0, BUTTON_HEIGHT+2*GUIDE_LABEL_HEIGHT, deviceFrameWidth, GUIDE_LABEL_HEIGHT)];
        distanceOutputlabel3.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:TRANSPARENT_ALPHA];
        distanceOutputlabel3.textAlignment = NSTextAlignmentLeft;
        distanceOutputlabel3.textColor = [UIColor whiteColor];
        distanceOutputlabel3.font=[UIFont systemFontOfSize:HEIGHT_OUTPUT_FONT_SIZE];
        distanceOutputlabel3.numberOfLines = 0;
        distanceOutputlabel3.text = @"";
        [distanceOutputlabel3 setHidden:YES];
        [self addSubview:distanceOutputlabel3];
        
        
        
        
        
        
        
        
        
    }
    return self;
}

-(void)startHeightCalculation{
    [self hideMenu];
    currentMeasuringMode=HEIGHT_MEASURING_MODE;
    nextGuide=HEIGHT_SLIDER_GUIDE;
    [markBaseButton setHidden:NO];
    if(showHeightGuide)
    {
        [self showInfo];
        nextGuide=MARK_BASE_GUIDE;
        timer=[NSTimer scheduledTimerWithTimeInterval:GUIDE_HIDE_INTERVAL target:self selector:@selector(showInfo) userInfo:nil repeats:NO];
    }
}
-(void)startDistanceCalculation{
    [self hideMenu];
    currentMeasuringMode=DISTANCE_MEASURING_MODE;
    nextGuide=HEIGHT_SLIDER_GUIDE;
    [markPositon1Button setHidden:NO];
    if(showDistanceGuide)
    {
        [self showInfo];
        nextGuide=MARK_POSITION1_GUIDE;
        timer=[NSTimer scheduledTimerWithTimeInterval:GUIDE_HIDE_INTERVAL target:self selector:@selector(showInfo) userInfo:nil repeats:NO];
    }
}

-(void)startDimensionCalculation{
    [self hideMenu];
    currentMeasuringMode=DIMENSION_MEASURING_MODE;
    nextGuide=HEIGHT_SLIDER_GUIDE;
    [calibrateButton setHidden:NO];
    if(showDimensionGuide)
    {
        [self showInfo];
        nextGuide=CALIBRATE_GUIDE;
        timer=[NSTimer scheduledTimerWithTimeInterval:GUIDE_HIDE_INTERVAL target:self selector:@selector(showInfo) userInfo:nil repeats:NO];
    }
}
-(void)hideMenu{
    [backgroundImageView setHidden:YES];
    [measureDimensionButton setHidden:YES];
    [measureDimensionButton setUserInteractionEnabled:NO];
    [measureHeightButton setHidden:YES];
    [measureHeightButton setUserInteractionEnabled:NO];
    [measureDistanceButton setHidden:YES];
    [measureDistanceButton setUserInteractionEnabled:NO];
    [homeButton setHidden:NO];
    [infoButton setHidden:NO];
    sliderValueLabel.alpha=1.0;
    heightSlider.alpha=1.0;
    crossHairView.alpha=1.0;
    [sliderValueLabel setHidden:NO];
    [heightSlider setHidden:NO];
    [crossHairView setHidden:NO];
    [unitPickerButton setHidden:NO];
    [dimensionInfoButton setHidden:YES];
    [distanceInfoButton setHidden:YES];
    [heightInfoButton setHidden:YES];
    [self fadeGuides];
    
}
-(void)showMenu{
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

-(void)showInfo{
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


-(void)showHeightInfo{
    UIImage *infoImage = [UIImage imageNamed:@"heightInfoImage.png"];

    infoImageView = [[UIImageView alloc] initWithImage:infoImage];
    infoImageView.frame = CGRectMake(0, (deviceFrameHeight-deviceFrameWidth)/2, deviceFrameWidth, deviceFrameWidth);
    [infoImageView setHidden:NO];
    [self addSubview:infoImageView];
    guideBackground  = [[UIView alloc] initWithFrame:CGRectMake(0, (deviceFrameHeight-deviceFrameWidth)/2, deviceFrameWidth, deviceFrameWidth)];
    guideBackground.backgroundColor = [UIColor clearColor];
    [self addSubview:guideBackground];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:GUIDE_CLEAR_INTERVAL target:self selector:@selector(fadeGuides) userInfo:nil repeats:NO];
    
    
}

-(void)showDistanceInfo{
    UIImage *infoImage = [UIImage imageNamed:@"distanceInfoImage.png"];
    infoImageView = [[UIImageView alloc] initWithImage:infoImage];
    infoImageView.frame = CGRectMake(0, (deviceFrameHeight-deviceFrameWidth)/2, deviceFrameWidth, deviceFrameWidth);
    [infoImageView setHidden:NO];
    [self addSubview:infoImageView];
    guideBackground  = [[UIView alloc] initWithFrame:CGRectMake(0, (deviceFrameHeight-deviceFrameWidth)/2, deviceFrameWidth, deviceFrameWidth)];
    guideBackground.backgroundColor = [UIColor clearColor];
    [self addSubview:guideBackground];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:GUIDE_CLEAR_INTERVAL target:self selector:@selector(fadeGuides) userInfo:nil repeats:NO];
}

-(void)showDimensionInfo{
    UIImage *infoImage = [UIImage imageNamed:@"dimensionInfoImage.png"];
    infoImageView = [[UIImageView alloc] initWithImage:infoImage];
    infoImageView.frame = CGRectMake(0, (deviceFrameHeight-deviceFrameWidth)/2, deviceFrameWidth, deviceFrameWidth);
    [infoImageView setHidden:NO];
    [self addSubview:infoImageView];
    guideBackground  = [[UIView alloc] initWithFrame:CGRectMake(0, (deviceFrameHeight-deviceFrameWidth)/2, deviceFrameWidth, deviceFrameWidth)];
    guideBackground.backgroundColor = [UIColor clearColor];
    [self addSubview:guideBackground];
    timer = [NSTimer scheduledTimerWithTimeInterval:GUIDE_CLEAR_INTERVAL target:self selector:@selector(fadeGuides) userInfo:nil repeats:NO];
    
    
}



-(void) selectUnit{
    UIActionSheet *actionSheet=[[UIActionSheet alloc]initWithTitle:@"Unit Picker" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Centimeter",@"Meter",@"Foot",@"Inch", nil];
    [actionSheet showInView:self];
}
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(buttonIndex >= MEASUREMENT_UNITS.count) {
        return;
    }
    currentUnit=(int)buttonIndex;
    [self adjustHeight];
}

-(void)setMenuView:(BOOL)value{
    if(!value)
    {
        [self hideMenu];
        [calibrateButton setHidden:NO];
        nextGuide=CALIBRATE_GUIDE;
    }
}





-(void)heightSliderGuide{
    guideBackground  = [[UIView alloc] initWithFrame:CGRectMake(2*SLIDER_WIDTH, 0, deviceFrameWidth-2*SLIDER_WIDTH, deviceFrameHeight)];
    guideBackground.backgroundColor = [UIColor colorWithRed:GUIDE_BACKGROUND_COLOR_RED green:GUIDE_BACKGROUND_COLOR_GREEN blue:GUIDE_BACKGROUND_COLOR_BLUE alpha:GUIDE_BACKGROUND_ALPHA];
    [self addSubview:guideBackground];
    UIImage *guideImage = [UIImage imageNamed:@"sliderGuideImage.png"];
    guideImageView = [[UIImageView alloc] initWithImage:guideImage];
    guideImageView.frame = CGRectMake(2*SLIDER_WIDTH,deviceFrameHeight-deviceFrameWidth, deviceFrameWidth, deviceFrameWidth);
    [self addSubview:guideImageView];
    timer = [NSTimer scheduledTimerWithTimeInterval:GUIDE_HIDE_INTERVAL target:self selector:@selector(fadeGuides) userInfo:nil repeats:NO];
    
}
-(void)calibrateGuide{
    
    [self showCrosshairAndButtonGuide:@"pointerGuideImage.png" forimage2:@"pointerGuideImageSmall.png" forimage3:@"calibrateGuideImage" fornextGuide:0];
    
}
-(void)captureGuide{
    
    [self showCrosshairAndButtonGuide:nil forimage2:nil forimage3:@"captureGuideImage.png" fornextGuide:0];
}
-(void)markBaseGuide{
    [self showCrosshairAndButtonGuide:@"pointerGuideImage1.png" forimage2:@"pointerGuideImageSmall1.png" forimage3:@"markbaseGuideImage.png" fornextGuide:0];
}
-(void)calculateHeightGuide{
    
     [self showCrosshairGuide:@"pointerGuideImage2.png" forimage2:@"pointerGuideImageSmall2"];
}
-(void)markPosition1Guide{
    
    [self showCrosshairAndButtonGuide:@"pointerGuideImage3.png" forimage2:@"pointerGuideImageSmall3.png" forimage3:@"markPosition1GuideImage.png" fornextGuide:0];
    
}
-(void)distanceGuide{
    
    [self showCrosshairGuide:@"pointerGuideImage4.png" forimage2:@"pointerGuideImageSmall4"];
}

-(void)showCrosshairGuide:(NSString*)image1 forimage2:(NSString*)image2
{
    int crossHairY=[[crossHairPositionForDeviceHeight objectForKey:[NSString stringWithFormat:@"%d",(int)deviceFrameHeight]] floatValue];
    guideBackground  = [[UIView alloc] initWithFrame:CGRectMake(0,crossHairY+CROSS_HAIR_HEIGHT, deviceFrameWidth, deviceFrameHeight-crossHairY-CROSS_HAIR_HEIGHT-BUTTON_HEIGHT)];
    guideBackground.backgroundColor = [UIColor colorWithRed:GUIDE_BACKGROUND_COLOR_RED green:GUIDE_BACKGROUND_COLOR_GREEN blue:GUIDE_BACKGROUND_COLOR_BLUE alpha:GUIDE_BACKGROUND_ALPHA];
    [self addSubview:guideBackground];
    if(deviceFrameHeight>MAXIMUM_DEVICE_HEIGHT_FOR_TOP_GUIDE)
    {
        UIImage *guideImage = [UIImage imageNamed:image1];
        guideImageView = [[UIImageView alloc] initWithImage:guideImage];
        guideImageView.frame = CGRectMake(deviceFrameWidth/2-CROSS_HAIR_WIDTH+POINTER_GUIDE_X_OFFSET,crossHairY+CROSS_HAIR_HEIGHT+POINTER_GUIDE_Y_OFFSET, GUIDE_IMAGE_SIZE, GUIDE_IMAGE_SIZE);
    }
    else
    {
        UIImage *guideImage = [UIImage imageNamed:image2];
        guideImageView = [[UIImageView alloc] initWithImage:guideImage];
        guideImageView.frame = CGRectMake(deviceFrameWidth/2+POINTER_GUIDE_Y_OFFSET_SMALL_1-CROSS_HAIR_WIDTH,crossHairY+CROSS_HAIR_HEIGHT+POINTER_GUIDE_Y_OFFSET, GUIDE_IMAGE_SIZE_SMALL, GUIDE_IMAGE_SIZE_SMALL);
    }
    [self addSubview:guideImageView];
    
    
    timer = [NSTimer scheduledTimerWithTimeInterval:GUIDE_CLEAR_INTERVAL target:self selector:@selector(fadeGuides) userInfo:nil repeats:NO];
}



-(void)showCrosshairAndButtonGuide:(NSString*)image1 forimage2:(NSString*)image2 forimage3:(NSString*)image3 fornextGuide:(int)nextGuideId
{
//    [self showGuides];
    int crossHairY=[[crossHairPositionForDeviceHeight objectForKey:[NSString stringWithFormat:@"%d",(int)deviceFrameHeight]] floatValue];
    if(deviceFrameHeight>MAXIMUM_DEVICE_HEIGHT_FOR_TOP_GUIDE)
    {
        if(image1!=nil)
        {
            guideBackground  = [[UIView alloc] initWithFrame:CGRectMake(0,crossHairY+CROSS_HAIR_HEIGHT, deviceFrameWidth, deviceFrameHeight-crossHairY-CROSS_HAIR_HEIGHT-BUTTON_HEIGHT)];
            guideBackground.backgroundColor = [UIColor colorWithRed:GUIDE_BACKGROUND_COLOR_RED green:GUIDE_BACKGROUND_COLOR_GREEN blue:GUIDE_BACKGROUND_COLOR_BLUE alpha:GUIDE_BACKGROUND_ALPHA];
            [self addSubview:guideBackground];
            UIImage *guideImage = [UIImage imageNamed:image1];
            guideImageView = [[UIImageView alloc] initWithImage:guideImage];
            guideImageView.frame = CGRectMake(deviceFrameWidth/2-CROSS_HAIR_WIDTH+POINTER_GUIDE_X_OFFSET,crossHairY+CROSS_HAIR_HEIGHT+POINTER_GUIDE_Y_OFFSET, GUIDE_IMAGE_SIZE, GUIDE_IMAGE_SIZE);
            [self addSubview:guideImageView];
       
        }
        else if(image3!=nil)
        {
            guideBackground1  = [[UIView alloc] initWithFrame:CGRectMake(0,crossHairY+CALIBERATE_GUIDE_Y_OFFSET, deviceFrameWidth,   deviceFrameHeight-crossHairY-BUTTON_HEIGHT-CALIBERATE_GUIDE_Y_OFFSET)];
            guideBackground1.backgroundColor = [UIColor colorWithRed:GUIDE_BACKGROUND_COLOR_RED green:GUIDE_BACKGROUND_COLOR_GREEN blue:GUIDE_BACKGROUND_COLOR_BLUE alpha:GUIDE_BACKGROUND_ALPHA];
            [self addSubview:guideBackground1];

        }
        
    }
    else
    {
        if(image2!=nil)
        {
            guideBackground  = [[UIView alloc] initWithFrame:CGRectMake(0,0, deviceFrameWidth, crossHairY+POINTER_GUIDE_Y_OFFSET_SMALL)];
            guideBackground.backgroundColor = [UIColor colorWithRed:GUIDE_BACKGROUND_COLOR_RED green:GUIDE_BACKGROUND_COLOR_GREEN blue:GUIDE_BACKGROUND_COLOR_BLUE alpha:GUIDE_BACKGROUND_ALPHA];
            [self addSubview:guideBackground];
            UIImage *guideImage = [UIImage imageNamed:image2];
            guideImageView = [[UIImageView alloc] initWithImage:guideImage];
            guideImageView.frame = CGRectMake(0,-POINTER_GUIDE_Y_OFFSET, GUIDE_IMAGE_SIZE_SMALL, GUIDE_IMAGE_SIZE_SMALL);
            [self addSubview:guideImageView];

        }
        if(image3!=nil)
        {
            guideBackground1  = [[UIView alloc] initWithFrame:CGRectMake(0,crossHairY+CALIBERATE_GUIDE_Y_OFFSET, deviceFrameWidth,   deviceFrameHeight-crossHairY-BUTTON_HEIGHT-CALIBERATE_GUIDE_Y_OFFSET)];
            guideBackground1.backgroundColor = [UIColor colorWithRed:GUIDE_BACKGROUND_COLOR_RED green:GUIDE_BACKGROUND_COLOR_GREEN blue:GUIDE_BACKGROUND_COLOR_BLUE alpha:GUIDE_BACKGROUND_ALPHA];
            [self addSubview:guideBackground1];

        }
    }
    if(image3!=nil)
    {
        UIImage *guideImage = [UIImage imageNamed:image3];
        guideImageView1 = [[UIImageView alloc] initWithImage:guideImage];
        guideImageView1.frame = CGRectMake(deviceFrameWidth/2-CALIBERATE_GUIDE_X_OFFSET,deviceFrameHeight-GUIDE_IMAGE_SIZE/4-BUTTON_HEIGHT, GUIDE_IMAGE_SIZE, GUIDE_IMAGE_SIZE);
        [self addSubview:guideImageView1];
     
    }
    if(nextGuideId>0)
        nextGuide=nextGuideId;
    timer = [NSTimer scheduledTimerWithTimeInterval:GUIDE_CLEAR_INTERVAL target:self selector:@selector(fadeGuides) userInfo:nil repeats:NO];
    
}


- (void) fadeGuides{
    [self fadeOutAnimateItem:guideImageView];
    [self fadeOutAnimateItem:guideImageView1];
    [self fadeOutAnimateItem:guideBackground];
    [self fadeOutAnimateItem:guideBackground1];
    [self fadeOutAnimateItem:infoImageView];
}
-(void)showGuides{
        [self fadeInAnimateItem:guideImageView];
        [self fadeInAnimateItem:guideImageView1];
        [self fadeInAnimateItem:guideBackground];
        [self fadeInAnimateItem:guideBackground1];
}

-(void)fadeOutAnimateItem:(UIView*)UIitem{
    NSLog(@"-------   %@",UIitem);
    [UIView beginAnimations:@"fade" context:nil];
    [UIView setAnimationDuration:ANIMATION_DURATION];
    UIitem.alpha=0.0;
    [UIView commitAnimations];
    
}



-(void)fadeInAnimateItem:(UIView*)UIitem{
    [UIView beginAnimations:@"fade" context:nil];
    [UIView setAnimationDuration:ANIMATION_DURATION];
    UIitem.alpha=1.0;
    [UIView commitAnimations];
}












-(void)adjustHeight{
    NSString *txt;
    float cameraHeightValue;
    cameraHeight=heightSlider.value;
    cameraHeightValue=cameraHeight*[MEASUREMENT_FACTORS[currentUnit] floatValue];
    switch (currentUnit) {
        case 0:txt=[NSString stringWithFormat:@"%.0f cm",cameraHeightValue];
            break;
        case 1:txt=[NSString stringWithFormat:@"%.2f m",cameraHeightValue];
            break;
        case 2:txt=[NSString stringWithFormat:@"%.2f ft",cameraHeightValue];
            break;
        case 3:txt=[NSString stringWithFormat:@"%.1f inch",cameraHeightValue];
            break;
        default:txt=@"Error";
            break;
    }
    CGRect frame = sliderValueLabel.frame;
    frame.origin.y=[self sliderThumbPosition:heightSlider];
    sliderValueLabel.frame=frame;
    sliderValueLabel.text=txt;
    switch (currentMeasuringMode) {
        case HEIGHT_MEASURING_MODE:
            nextGuide=MARK_BASE_GUIDE;
            break;
        case DISTANCE_MEASURING_MODE:
            nextGuide=MARK_POSITION1_GUIDE;
            break;
        case DIMENSION_MEASURING_MODE:
            nextGuide=CALIBRATE_GUIDE;
            break;
        default:
            break;

    }
    [self fadeGuides];
}
- (float)sliderThumbPosition:(UISlider *)slider;
{
    float sliderRange,sliderStartPosition,sliderPixelHeight,labelPosition;
    float correctionFactor=SLIDER_VALUE_POSTION_CORRECTION_OFFSET-(slider.value/SLIDER_VALUE_POSTION_CORRECTION_FACTOR);
    sliderRange = slider.frame.size.height - slider.currentThumbImage.size.height;
    sliderStartPosition = slider.frame.origin.y + (slider.currentThumbImage.size.height / 2.0);
    sliderPixelHeight = (((slider.value-slider.minimumValue)/(slider.maximumValue-slider.minimumValue )) * sliderRange) + sliderStartPosition;
    labelPosition=deviceFrameHeight-sliderPixelHeight+correctionFactor;
    return labelPosition;
}


-(void)calibrate{
    float angle;
    CMAttitude *attitude;
    CMDeviceMotion *motion;
    motion= motionManager.deviceMotion;
    attitude = motion.attitude;
    angle=attitude.pitch;
    if(angle<0)
        angle=-angle;
    distance=cameraHeight*tan(angle);
    [calibrateButton setHidden:YES];
    [unitPickerButton setHidden:YES];
    [captureButton setHidden:NO];
    [recalibrateButton setHidden:NO];
    [self fadeInAnimateItem:recalibrateButton];
    [self fadeOutAnimateItem:crossHairView];
    [self fadeOutAnimateItem:heightSlider];
    [self fadeOutAnimateItem:sliderValueLabel];
    nextGuide=CAPTURE_GUIDE;
    [self fadeGuides];
    if(showDimensionGuide)
    {
        guideBackground1.alpha=0;
        guideImageView1.alpha=0;
        guideBackground.alpha=0;
        guideImageView.alpha=0;
        [self showInfo];
        showDistanceGuide=NO;
    }

    
}
-(void)enableCalibrate{
    [calibrateButton setHidden:NO];
    [unitPickerButton setHidden:NO];
    [captureButton setHidden:YES];
    [recalibrateButton setHidden:YES];
    [self fadeInAnimateItem:crossHairView];
    [self fadeInAnimateItem:heightSlider];
    [self fadeInAnimateItem:sliderValueLabel];
    nextGuide=CALIBRATE_GUIDE;
    [self fadeGuides];
    
}
-(void) takePhoto{
    [self.viewController callBack:distance];
    [self fadeGuides];
}
-(void)markBase{
    CMAttitude *attitude;
    CMDeviceMotion *motion;
    float angleOfTilt;
    motion= motionManager.deviceMotion;
    attitude = motion.attitude;
    angleOfTilt=attitude.pitch;
    yawChange=NO;
    initialPosition=POSITIVE_YAW;
    if(attitude.yaw<0)
        initialPosition=NEGATIVE_YAW;
    if(angleOfTilt<0)
        angleOfTilt=-angleOfTilt;
    previousPosition=initialPosition;
    distance=cameraHeight*tan(angleOfTilt);
    [heightOutputLabel setHidden:NO];
    objectHigherThanCamera=NO;
    timer = [NSTimer scheduledTimerWithTimeInterval:HEIGHT_UPDATE_INTERVAL target:self selector:@selector(calculateHeight) userInfo:nil repeats:YES];
    nextGuide=CALCULATE_HEIGHT_GUIDE;
    if(showHeightGuide)
    {
        guideBackground1.alpha=0;
        guideImageView1.alpha=0;
        guideBackground.alpha=0;
        guideImageView.alpha=0;
        [self showInfo];
        showHeightGuide=NO;
        
    }

}

-(void)calculateHeight{
    float angleOfTilt,height;
    CMAttitude *attitude;
    CMDeviceMotion *motion;
    NSString *txt;
    motion= motionManager.deviceMotion;
    attitude = motion.attitude;
    angleOfTilt=attitude.pitch;
    finalPostion=POSITIVE_YAW;
    if(attitude.yaw<0)
        finalPostion=NEGATIVE_YAW;
    if((previousPosition!=finalPostion)&&((degrees(M_PI_2)-degrees(angleOfTilt))>YAW_CHANGE_CUTOFF_ANGLE))
    {
        if(initialPosition!=previousPosition)
            initialPosition=previousPosition;
        else
            initialPosition=finalPostion;
    }
    previousPosition=finalPostion;
    if(angleOfTilt<0)
        angleOfTilt=-angleOfTilt;
   
    if(initialPosition==finalPostion)
    {
        height=cameraHeight-(distance/tan(angleOfTilt));
    }
    else
    {
        angleOfTilt=(M_PI_2)-angleOfTilt;
        height=cameraHeight+(distance*tan(angleOfTilt));
    }
    if(height>0)
    {
        height=height*[MEASUREMENT_FACTORS[currentUnit] floatValue];
        switch (currentUnit) {
            case 0:txt=[NSString stringWithFormat:@"Height  : %.1f cm",height];
                break;
            case 1:txt=[NSString stringWithFormat:@"Height  : %.2f m",height];
                break;
            case 2:txt=[NSString stringWithFormat:@"Height  : %.2f ft",height];
                break;
            case 3:txt=[NSString stringWithFormat:@"Height  : %.1f inch",height];
                break;
            default:txt=@"Error";
                break;
        }
    }
    else
    {
       txt=@"Move from base to top";
    }
    
    
    
    heightOutputLabel.text=txt;
    
}

-(void)markPosition1{
    CMAttitude *attitude;
    CMDeviceMotion *motion;
    float angleOfTilt;
    motion= motionManager.deviceMotion;
    attitude = motion.attitude;
    angleOfTilt=attitude.pitch;
    if(angleOfTilt<0)
        angleOfTilt=-angleOfTilt;
    distance=cameraHeight*tan(angleOfTilt);
    timer = [NSTimer scheduledTimerWithTimeInterval:DISTANCE_UPDATE_INTERVAL target:self selector:@selector(calculateDistance) userInfo:nil repeats:YES];
    [distanceOutputlabel1 setHidden:NO];
    [distanceOutputlabel2 setHidden:NO];
    [distanceOutputlabel3 setHidden:NO];
    nextGuide=DISTANCE_GUIDE;
    [self fadeGuides];
    if(showDistanceGuide)
    {
        guideBackground1.alpha=0;
        guideImageView1.alpha=0;
        guideBackground.alpha=0;
        guideImageView.alpha=0;
        
        timer = [NSTimer scheduledTimerWithTimeInterval:GUIDE_UPDATE_INTERVAL2 target:self selector:@selector(showInfo) userInfo:nil repeats:NO];
        showDistanceGuide=NO;
    }

    
}
-(void)calculateDistance{
    CMAttitude *attitude;
    CMDeviceMotion *motion;
    NSString *txt;
    float angleOfTilt,distanceToPosition1,distanceToPosition2,distanceBetweenPoints;
    motion= motionManager.deviceMotion;
    attitude = motion.attitude;
    angleOfTilt=attitude.pitch;
    if(angleOfTilt<0)
        angleOfTilt=-angleOfTilt;
    distanceToPosition2=cameraHeight*tan(angleOfTilt);
    distanceBetweenPoints=fabsf(distanceToPosition2-distance);
    
    distanceToPosition1=distance*[MEASUREMENT_FACTORS[currentUnit] floatValue];
    switch (currentUnit) {
        case 0:txt=[NSString stringWithFormat:@"Distance To Position 1     : %.1f cm",distanceToPosition1];
            break;
        case 1:txt=[NSString stringWithFormat:@"Distance To Position 1     : %.2f m",distanceToPosition1];
            break;
        case 2:txt=[NSString stringWithFormat:@"Distance To Position 1     : %.2f ft",distanceToPosition1];
            break;
        case 3:txt=[NSString stringWithFormat:@"Distance To Position 1     : %.1f inch",distanceToPosition1];
            break;
        default:txt=@"Error";
            break;
    }
    distanceOutputlabel1.text=txt;
    distanceToPosition2=distanceToPosition2*[MEASUREMENT_FACTORS[currentUnit] floatValue];
    switch (currentUnit) {
        case 0:txt=[NSString stringWithFormat:@"Distance To Position 2     : %.1f cm",distanceToPosition2];
            break;
        case 1:txt=[NSString stringWithFormat:@"Distance To Position 2     : %.2f m",distanceToPosition2];
            break;
        case 2:txt=[NSString stringWithFormat:@"Distance To Position 2     : %.2f ft",distanceToPosition2];
            break;
        case 3:txt=[NSString stringWithFormat:@"Distance To Position 2     : %.1f inch",distanceToPosition2];
            break;
        default:txt=@"Error";
            break;
    }
    distanceOutputlabel2.text=txt;
    distanceBetweenPoints=distanceBetweenPoints*[MEASUREMENT_FACTORS[currentUnit] floatValue];
    switch (currentUnit) {
        case 0:txt=[NSString stringWithFormat:@"Distance Between Them : %.1f cm",distanceBetweenPoints];
            break;
        case 1:txt=[NSString stringWithFormat:@"Distance Between Them : %.2f m",distanceBetweenPoints];
            break;
        case 2:txt=[NSString stringWithFormat:@"Distance Between Them : %.2f ft",distanceBetweenPoints];
            break;
        case 3:txt=[NSString stringWithFormat:@"Distance Between Them : %.1f inch",distanceBetweenPoints];
            break;
        default:txt=@"Error";
            break;
    }
    distanceOutputlabel3.text=txt;
    
    
}





-(BOOL) shouldAutorotate {
    return NO;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self fadeGuides];
}


//-(void)test
//{
//    CMAttitude *attitude;
//    CMDeviceMotion *motion;
//    motion= motionManager.deviceMotion;
//    attitude = motion.attitude;
//    angle=attitude.pitch;
//    initpos=1;
//    if(attitude.yaw<0)
//        initpos=-1;
//    if(angle<0)
//        angle=-angle;
//    distance=cameraHeight*tan(angle);
//    float heightWithoutTilt,x,pitch,originaldist;
//    x=30.4;
//    heightWithoutTilt=2*distance*tan(radians(x));
//    pitch=attitude.pitch;
//    originaldist=(heightWithoutTilt*sin(radians((90-x))))/sin(radians(degrees(pitch)-x));
//    txt =[NSString stringWithFormat:@"WT%0.01f OH%0.01f PD%0.01f",heightWithoutTilt,originaldist,distance];
//    guide.text=txt;
//    
//}


@end
