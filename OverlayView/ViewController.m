//
//  ViewController.m
//  OverlayView
//
//  Created by user on 21/04/15.
//  Copyright (c) 2015 user. All rights reserved.
//

#import "ViewController.h"
#import "CameraOverlay.h"
#import "AppDelegate.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "Constants.h"

@interface ViewController() {
    
    int currentUnit;
    float tiltOfPhone, ratio, heightWithoutTilt, deviceFrameWidth, deviceFrameHeight, cameraFieldOfView, distanceToObject;
    BOOL firstView, distanceOutputPositionFlag, unitPickerUsed;
    NSDictionary *fieldOfViewForDevices;
    ImagePickerViewController *picker;
    CAShapeLayer *shapeLayer;
    NSArray *cameraType;
    CGPoint point1, point2;
    
}
@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self initialiseGlobalVariables];
    
    _point1Button.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    _point2Button.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    
    distanceOutput = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, DISTANCE_OUTPUT_WIDTH, DISTANCE_OUTPUT_HEIGHT)];
    distanceOutput.text = @"";
    distanceOutput.backgroundColor = [UIColor colorWithRed:0
                                                     green:0
                                                      blue:0
                                                     alpha:TRANSPARENT_ALPHA];
    distanceOutput.textColor = [UIColor whiteColor];
    distanceOutput.textAlignment = NSTextAlignmentCenter;
    
    [self.view addSubview:distanceOutput];
    [self setDistanceOutputPosition];
    [self.view setHidden:YES];
    
    //For calculating distance, based on two marker positions
    timer = [NSTimer scheduledTimerWithTimeInterval:FUNCTION_CALL_INTERVAL
                                             target:self
                                           selector:@selector(calculateDistance)
                                           userInfo:nil
                                            repeats:YES];
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:YES];
    
    point1 = _point1Button.frame.origin;
    point1.y += INITIAL_LINE_Y;
    point1.x += INITIAL_LINE_X;
    
    point2 = _point2Button.frame.origin;
    point2.y += INITIAL_LINE_Y;
    point2.x += INITIAL_LINE_X;
    
    [self setDistanceOutputPosition];
    
    if (!shapeLayer) {
        
        [self createShapeLayer];
        
    }
    
    shapeLayer.path = [[self pathFrom:point2
                                   to:point1 ] CGPath];
    
    if (firstView) {
        
        [self showOverlay:YES];
        
    }
    else {
        
        [self.view setHidden:NO];
        
    }
    
}

- (void)initialiseGlobalVariables {
    
    firstView = YES;
    unitPickerUsed = NO;
    fieldOfViewForDevices = FIELD_OF_VIEW_CONSTANTS;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    deviceFrameWidth = screenRect.size.width;
    deviceFrameHeight = screenRect.size.height;
    
    motionManager = [[CMMotionManager alloc]init];
    motionManager.deviceMotionUpdateInterval = MOTION_UPDATE_INTERVAL;
    [motionManager startGyroUpdates];
    [motionManager startDeviceMotionUpdates];
    [motionManager startAccelerometerUpdates];
}


#pragma mark - IBActions

//For going back to the image capture option
- (IBAction)goBack:(id)sender {
    
    firstView = YES;
    [self showOverlay:NO];
    
}

//For going back to the main menu
- (IBAction)goToHome:(id)sender {
    
    [self showOverlay:YES];
    
}

- (IBAction)pointButtonDrag:(id)sender withEvent:(UIEvent *) event  {
    
    CGPoint currentPoint, buttonPoint, linePoint;
    UIButton *currentButton;
    
    currentPoint = [[[event allTouches] anyObject] locationInView:self.view];
    currentButton = sender;
    buttonPoint.x = currentPoint.x + BUTTON_DRAG_OFFSET_X;
    buttonPoint.y = currentPoint.y + BUTTON_DRAG_OFFSET_Y;
    linePoint.x = currentPoint.x + LINE_OFFSET_X;
    linePoint.y = currentPoint.y + LINE_OFFSET_Y;
    
    if(currentButton.tag == BUTTON1TAG) {
        
        point1 = linePoint;
        
    }
    else if(currentButton.tag == BUTTON2TAG) {
        
        point2 = linePoint;
        
    }
    
    currentButton.center = buttonPoint;
    
    if (!shapeLayer) {
        
        [self createShapeLayer];
        
    }
    
    shapeLayer.path = [[self pathFrom:point1
                                   to:point2 ] CGPath];
    
}

//For selecting the units
- (IBAction)selectUnits:(id)sender {
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:@"Unit Picker"
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:@"Centimeter", @"Meter", @"Foot", @"Inch", nil];
    [actionSheet showInView:self.view];
    unitPickerUsed = YES;
    
}

//For showing the guide
- (IBAction)viewGuide:(id)sender {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"User Info"
                                                    message:@"Drag the markers to measure the distance"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    
}


#pragma mark - Create Camera Overlay

//For showing the camera overlay
- (void)showOverlay:(BOOL)startscreen {
    
    picker = [[ImagePickerViewController alloc] init];
    picker.delegate = self;
    CameraOverlay *overlay = [[CameraOverlay alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    overlay.viewController = self;
    
    if(startscreen)
        distanceToObject = 0;
    
    [overlay setMenuView:startscreen forDistance:distanceToObject];
    
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.showsCameraControls = NO;
    picker.navigationBarHidden = YES;
    [picker.view addSubview:overlay];
    cameraType=picker.mediaTypes;
    picker.mediaTypes = @[(NSString *)kUTTypeMovie];

    picker.view.multipleTouchEnabled = NO;

    [self presentViewController:picker
                       animated:YES
                     completion:nil];
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    

    float heightWithTilt, angle1, angle2, angle3, angle4, angle5, side2, side3, diagonal;
    UIImage *image = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    _capturedImageView.image = image;
    
    angle1 = 90 + cameraFieldOfView;
    side3 = heightWithoutTilt;
    side2 = (distanceToObject / cos(radians(90 + cameraFieldOfView - degrees(tiltOfPhone)))) - (distanceToObject / cos(radians(cameraFieldOfView)));
    
    diagonal = (side2 * side2) + (side3 * side3) - (2 * side2 * side3 * cos(radians(angle1)));
    diagonal = sqrtf(diagonal);
    
    angle2 = angle1;
    angle5 = asin(side2 * sin(radians(angle1)) / diagonal);
    angle5 = angle2 - degrees(angle5);
    angle3 = degrees(tiltOfPhone) - cameraFieldOfView;
    angle4 = 360 - angle1 - angle2 - angle3;
    
    heightWithTilt = (diagonal * sin(radians(angle5)) / sin(radians(angle4)));
    ratio = heightWithTilt / _capturedImageView.frame.size.height;
    
    if(ratio < 0)
        ratio = - ratio;
    
    [self dismissViewControllerAnimated:YES
                             completion:nil];
    
}

//Returning from the overlay view
- (void)callBack:(float) distance {
    
    cameraFieldOfView = [[fieldOfViewForDevices objectForKey:[NSString stringWithFormat:@"%d", (int)deviceFrameHeight]] floatValue];
    firstView = NO;
    picker.mediaTypes=cameraType;
    [picker takePicture];
    
    CMAttitude *attitude;
    CMDeviceMotion *motion;
    
    motion = motionManager.deviceMotion;
    attitude = motion.attitude;
    tiltOfPhone = attitude.pitch;
    distanceToObject = distance;
    heightWithoutTilt = 2 * distanceToObject * tan(radians(cameraFieldOfView));
    
    if(heightWithoutTilt < 0)
        heightWithoutTilt = - heightWithoutTilt;
    
}

#pragma mark - Calculation and Drawing

//For calculating the distance
- (void)calculateDistance {
    
    int x1, x2, y1, y2;
    float distanceOnImage, originalDistance;
    NSString *txt;
    
    x1 = (int)_point1Button.frame.origin.x;
    y1 = (int)_point1Button.frame.origin.y;
    x2 = (int)_point2Button.frame.origin.x;
    y2 = (int)_point2Button.frame.origin.y;
    
    if(unitPickerUsed) {
        
        [self repositionButton];
        unitPickerUsed = NO;
        
    }
    
    distanceOnImage = sqrtf((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
    originalDistance = (distanceOnImage*ratio) * [MEASUREMENT_FACTORS[currentUnit] floatValue];
    
    switch (currentUnit) {
            
        case 0:txt = [NSString stringWithFormat:@"%.2f cm", originalDistance];
            break;
        case 1:txt = [NSString stringWithFormat:@"%.2f m", originalDistance];
            break;
        case 2:txt = [NSString stringWithFormat:@"%.2f ft", originalDistance];
            break;
        case 3:txt = [NSString stringWithFormat:@"%.1f inch", originalDistance];
            break;
        default:txt = @"Error";
            break;
            
    }
    
    distanceOutput.text = txt;
    [self setDistanceOutputPosition];
    
}

//For repositioning the button
- (void)repositionButton {
    
    CGPoint buttonPoint;
    
    buttonPoint.x = point1.x - LINE_OFFSET_X + BUTTON_DRAG_OFFSET_X;
    buttonPoint.y = point1.y - LINE_OFFSET_Y + BUTTON_DRAG_OFFSET_Y;
    _point1Button.center = buttonPoint;
    
    buttonPoint.x = point2.x - LINE_OFFSET_X + BUTTON_DRAG_OFFSET_X;
    buttonPoint.y = point2.y - LINE_OFFSET_Y + BUTTON_DRAG_OFFSET_Y;
    _point2Button.center = buttonPoint;
    
}

//For creating a shapelayer to draw a line between two markers
- (void)createShapeLayer {
    
    shapeLayer = [CAShapeLayer layer];
    shapeLayer.lineWidth = LINE_WIDTH;
    shapeLayer.strokeColor = [[UIColor colorWithRed:BACKGROUND_COLOR_RED
                                              green:BACKGROUND_COLOR_GREEN
                                               blue:BACKGROUND_COLOR_BLUE
                                              alpha:FULL_OPAQUE_ALPHA] CGColor];
    shapeLayer.fillColor = [[UIColor clearColor] CGColor];
    [self.view.layer addSublayer:shapeLayer];
    
}

//For drawing a line between two markers
- (UIBezierPath *)pathFrom:(CGPoint)start to:(CGPoint)end {
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:start];
    [path addLineToPoint:end];
    
    return path;
    
}


//For positioning the output label adjacent to the line between two markers
- (void)setDistanceOutputPosition {
    
    CGPoint outputPoint;
    outputPoint.y = [self getDistanceLabelY];
    outputPoint.x = [self getDistanceLabelX];
    distanceOutput.center = outputPoint;
    
}

//To obtain the x coordinate for distance output label
- (int)getDistanceLabelX {
    
    int labelPositionX;
    labelPositionX = (point1.x + point2.x ) / 2;
    
    if(distanceOutputPositionFlag) {
        
        if(labelPositionX < deviceFrameWidth - OUTPUT_LABEL_LINE_HORIZONTAL_OFFSET - (DISTANCE_OUTPUT_WIDTH / 2))
            labelPositionX += OUTPUT_LABEL_LINE_HORIZONTAL_OFFSET;
        
        else
            labelPositionX -= OUTPUT_LABEL_LINE_HORIZONTAL_OFFSET;
        
    }
    
    else {
        
        if(labelPositionX < DISTANCE_OUTPUT_WIDTH / 2)
            labelPositionX = DISTANCE_OUTPUT_WIDTH / 2;
        
        else if(labelPositionX > deviceFrameWidth - DISTANCE_OUTPUT_WIDTH / 2)
            labelPositionX = deviceFrameWidth - DISTANCE_OUTPUT_WIDTH / 2;
        
    }
    
    return labelPositionX;
    
}


//To obtain the y coordinate for distance output label
- (int)getDistanceLabelY {
    
    int labelPositionY, higherY = 0, lowerY = 0;
    
    if(point1.y > point2.y) {
        
        higherY = point1.y;
        lowerY = point2.y;
        
    }
    else {
        
        higherY = point2.y;
        lowerY = point1.y;
        
    }
    distanceOutputPositionFlag = NO;
    
    if(higherY < deviceFrameHeight - (DISTANCE_OUTPUT_HEIGHT / 2) - OUTPUT_LABEL_LINE_VERTICAL_OFFSET)
        labelPositionY = higherY + OUTPUT_LABEL_LINE_VERTICAL_OFFSET;
    
    else if(lowerY > TOP_BAR_HEIGHT + deviceFrameHeight / 2) {
        
        if(abs(point1.x - point2.x) > DISTANCE_OUTPUT_WIDTH + MARKER_BUTTON_WIDTH)
            labelPositionY = lowerY - OUTPUT_LABEL_LINE_VERTICAL_OFFSET;
        
        else
            labelPositionY = lowerY - OUTPUT_LABEL_LINE_VERTICAL_OFFSET - MARKER_BUTTON_HEIGHT;
    }
    
    else {
        
        labelPositionY = (lowerY + higherY) / 2;
        distanceOutputPositionFlag = YES;
        
    }
    
    if(abs(point1.y - point2.y) > MARKER_BUTTON_HEIGHT + deviceFrameWidth / 3 + OUTPUT_LABEL_LINE_VERTICAL_OFFSET) {
        
        labelPositionY = (lowerY + higherY) / 2;
        distanceOutputPositionFlag = YES;
        
        if(abs(point1.y - point2.y) < deviceFrameWidth / 2)
            labelPositionY += OUTPUT_LABEL_LINE_VERTICAL_OFFSET;
        
    }
    
    return labelPositionY;
    
}

#pragma mark -

- (BOOL)shouldAutorotate {
    
    return NO;
    
}

- (BOOL)prefersStatusBarHidden {
    
    return YES;
    
}

#pragma mark - UIActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if(buttonIndex >= MEASUREMENT_UNITS.count) {
        
        return;
        
    }
    
    currentUnit = (int)buttonIndex;
    
}

- (void)setTypeAsCamera {
    
    picker.mediaTypes=cameraType;
    [picker takePicture];

    
}

- (void)setTypeAsVideo {
    
    picker.mediaTypes= @[(NSString *)kUTTypeMovie];;
    [picker takePicture];
    
    
}

@end
