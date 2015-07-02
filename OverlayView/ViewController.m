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
//#import "Constants.h"




#define radians(x) ((x) / 180.0 * M_PI)
#define degrees(x) (180 * x / M_PI)
#define CAMERA_TRANSFORM_X 1
#define CAMERA_TRANSFORM_Y 1.24299
#define BUTTON1TAG 1
#define BUTTON2TAG 2
#define MEASUREMENT_FACTORS @[@"1.00",@"0.01",@"0.0328084",@"0.393701"]
#define MEASUREMENT_UNITS  @[@"Centimeter", @"Meter", @"Foot", @"Inch"]
#define MEASUREMENT_UNITS_SHORT_FORM  @[@"cm", @"m", @"ft", @"inch"]
#define BUTTON_CORNER_RADIUS 20
#define BUTTON_DRAG_OFFSET_X -15
#define BUTTON_DRAG_OFFSET_Y 30
#define LINE_OFFSET_X -16
#define LINE_OFFSET_Y 52
#define INITIAL_LINE_X 19
#define INITIAL_LINE_Y 52
#define MOTION_UPDATE_INTERVAL 0.1
#define FUNCTION_CALL_INTERVAL 0.25
#define DISTANCE_OUTPUT_WIDTH 120
#define DISTANCE_OUTPUT_HEIGHT 30
#define OUTPUT_LABEL_LINE_VERTICAL_OFFSET 20
#define OUTPUT_LABEL_LINE_HORIZONTAL_OFFSET 85
#define TRANSPARENT_ALPHA 0.4
#define TOP_BAR_HEIGHT 42
#define MARKER_BUTTON_HEIGHT 52
#define MARKER_BUTTON_WIDTH 41






@interface ViewController (){
    BOOL firstView,distanceOutputPositionFlag,unitPickerUsed;
    ImagePickerViewController *picker;
    CAShapeLayer *shapeLayer;
    CGPoint point1,point2;
    float tiltOfPhone,ratio,heightWithoutTilt,deviceFrameWidth,deviceFrameHeight,cameraFieldOfView;;
    int currentUnit;
    NSDictionary *fieldOfViewForDevices;
 
}

@end
@implementation ViewController



- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    firstView = YES;
    unitPickerUsed=NO;
    
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    deviceFrameWidth = screenRect.size.width;
    deviceFrameHeight = screenRect.size.height;
    
    motionManager = [[CMMotionManager alloc]init];
    motionManager.deviceMotionUpdateInterval = MOTION_UPDATE_INTERVAL;
    [motionManager startGyroUpdates];
    [motionManager startDeviceMotionUpdates];
    [motionManager startAccelerometerUpdates];

        fieldOfViewForDevices = [[NSDictionary alloc] initWithObjectsAndKeys:@"23.75", @"480",@"24.7",@"736",@"19.5",@"1024",@"22.5",@"568",nil];
    //CROSS HAIR POSITION DICTIONARY FOR VARIOUS DEVICE HEIGHTS
    
    _point1Button.layer.cornerRadius=BUTTON_CORNER_RADIUS;
    _point2Button.layer.cornerRadius=BUTTON_CORNER_RADIUS;
    
    
    distanceOutput = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, DISTANCE_OUTPUT_WIDTH,DISTANCE_OUTPUT_HEIGHT)];
    distanceOutput.text = @"Adjust the slider on the left to set camera height";
    distanceOutput.backgroundColor=[UIColor colorWithRed:0 green:0 blue:0 alpha:TRANSPARENT_ALPHA];
    distanceOutput.textColor=[UIColor whiteColor];
    distanceOutput.textAlignment=NSTextAlignmentCenter;
    [self.view addSubview:distanceOutput];
    [self setDistanceOutputPosition];
    
    [self.view setHidden:YES];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:FUNCTION_CALL_INTERVAL target:self selector:@selector(calculateDistance) userInfo:nil repeats:YES];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:YES];
    
    point1=_point1Button.frame.origin;
    point1.y+=INITIAL_LINE_Y;
    point1.x+=INITIAL_LINE_X;
    point2=_point2Button.frame.origin;
    point2.y+=INITIAL_LINE_Y;
    point2.x+=INITIAL_LINE_X;
    
    [self setDistanceOutputPosition];
    
    if (!shapeLayer) {
        [self createShapeLayer];
    }
    shapeLayer.path = [[self arrowPathFrom:point2 to:point1 ] CGPath];

    if (firstView) {
        [self showOverlay:YES];
    }
    else{
        [self.view setHidden:NO];
    }

}

- (void)showOverlay:(BOOL)startscreen{
    
    picker = [[ImagePickerViewController alloc] init];
    picker.delegate = self;
    CameraOverlay *overlay = [[CameraOverlay alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    overlay.viewController = self;
    [overlay setMenuView:startscreen];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.showsCameraControls = NO;
    picker.navigationBarHidden = YES;
    picker.cameraViewTransform = CGAffineTransformScale(picker.cameraViewTransform, CAMERA_TRANSFORM_X, CAMERA_TRANSFORM_Y);
    [picker.view addSubview:overlay];
    picker.view.multipleTouchEnabled=NO;

    [self presentViewController:picker animated:YES completion:nil];
}



-  (IBAction)pointButtonDrag:(id)sender withEvent:(UIEvent *) event  {
    CGPoint currentPoint,buttonPoint,linePoint;
    UIButton *currentButton;
    currentPoint = [[[event allTouches] anyObject] locationInView:self.view];
    currentButton=sender;
    buttonPoint.x = currentPoint.x+BUTTON_DRAG_OFFSET_X;
    buttonPoint.y = currentPoint.y+BUTTON_DRAG_OFFSET_Y;
    linePoint.x   = currentPoint.x+LINE_OFFSET_X;
    linePoint.y   = currentPoint.y+LINE_OFFSET_Y;
    if(currentButton.tag==BUTTON1TAG)
    {
        point1=linePoint;
    }
    else if(currentButton.tag==BUTTON2TAG)
    {
        point2=linePoint;
    }
    currentButton.center=buttonPoint;
    if (!shapeLayer) {
        [self createShapeLayer];
    }
    shapeLayer.path = [[self arrowPathFrom:point1 to:point2 ] CGPath];

}

- (void)calculateDistance {
    int x1,x2,y1,y2;
    float distanceOnImage,originalDistance;
    NSString *txt;
    
    
    x1=(int)_point1Button.frame.origin.x;
    y1=(int)_point1Button.frame.origin.y;
    x2=(int)_point2Button.frame.origin.x;
    y2=(int)_point2Button.frame.origin.y;
    if(unitPickerUsed)
    {
        CGPoint buttonPoint;
        buttonPoint.x=point1.x-LINE_OFFSET_X+BUTTON_DRAG_OFFSET_X;
        buttonPoint.y=point1.y-LINE_OFFSET_Y+BUTTON_DRAG_OFFSET_Y;
        _point1Button.center=buttonPoint;
        buttonPoint.x=point2.x-LINE_OFFSET_X+BUTTON_DRAG_OFFSET_X;
        buttonPoint.y=point2.y-LINE_OFFSET_Y+BUTTON_DRAG_OFFSET_Y;
        _point2Button.center=buttonPoint;
        unitPickerUsed=NO;
    }
    distanceOnImage=sqrtf((x2-x1)*(x2-x1)+(y2-y1)*(y2-y1));
    originalDistance=(distanceOnImage*ratio)*[MEASUREMENT_FACTORS[currentUnit] floatValue];
    switch (currentUnit) {
        case 0:txt=[NSString stringWithFormat:@"%.2f cm",originalDistance];
            break;
        case 1:txt=[NSString stringWithFormat:@"%.2f m",originalDistance];
            break;
        case 2:txt=[NSString stringWithFormat:@"%.2f ft",originalDistance];
            break;
        case 3:txt=[NSString stringWithFormat:@"%.1f inch",originalDistance];
            break;
        default:txt=@"Error";
            break;
    }
    distanceOutput.text=txt;
    [self setDistanceOutputPosition];
}

- (IBAction)goBack:(id)sender {
    firstView=YES;
    [self showOverlay:NO];
}

- (IBAction)goToHome:(id)sender {
        [self showOverlay:YES];
}

- (IBAction)viewGuide:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"User Info" message:@"Drag the markers to measure the distance" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}


- (IBAction)selectUnits:(id)sender {
    UIActionSheet *actionSheet=[[UIActionSheet alloc]initWithTitle:@"Unit Picker" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Centimeter",@"Meter",@"Foot",@"Inch", nil];
    [actionSheet showInView:self.view];
    unitPickerUsed=YES;
}

- (void)callBack:(float) distance{

    cameraFieldOfView=[[fieldOfViewForDevices objectForKey:[NSString stringWithFormat:@"%d",(int)deviceFrameHeight]] floatValue];
    firstView = NO;
    [picker takePicture];
    CMAttitude *attitude;
    CMDeviceMotion *motion;
    motion= motionManager.deviceMotion;
    attitude = motion.attitude;
    tiltOfPhone=attitude.pitch;
    heightWithoutTilt=2*distance*tan(radians(cameraFieldOfView));
    if(heightWithoutTilt<0)
        heightWithoutTilt=-heightWithoutTilt;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    float heightWithTilt;
    UIImage *image = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    _capturedImageView.image = image;
    heightWithTilt=(heightWithoutTilt*sin(radians((90-cameraFieldOfView))))/sin(radians(degrees(tiltOfPhone)-cameraFieldOfView));
    ratio=heightWithTilt/_capturedImageView.frame.size.height;
    if(ratio<0)
        ratio=-ratio;
    [self dismissViewControllerAnimated:YES completion:nil];

}

-(BOOL) shouldAutorotate {
    return NO;
}

-(BOOL)prefersStatusBarHidden{
    return YES;
}





- (void)createShapeLayer
{
    shapeLayer = [CAShapeLayer layer];
    shapeLayer.lineWidth = 3;
    shapeLayer.strokeColor = [[UIColor colorWithRed:0.23137254902 green:0.34901960784 blue:0.59607843137 alpha:1] CGColor];
    shapeLayer.fillColor = [[UIColor clearColor] CGColor];
    [self.view.layer addSublayer:shapeLayer];
}

- (UIBezierPath *)arrowPathFrom:(CGPoint)start to:(CGPoint)end 
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:start];
    [path addLineToPoint:end];
    return path;
}
-(void) setDistanceOutputPosition{
    CGPoint outputPoint;
    outputPoint.y=[self getDistanceLabelY];
    outputPoint.x=[self getDistanceLabelX];
    distanceOutput.center=outputPoint;
}


-(int) getDistanceLabelX{
    int labelPositionX;
    labelPositionX=(point1.x+point2.x )/2;
    if(distanceOutputPositionFlag)
    {
        if(labelPositionX<deviceFrameWidth-OUTPUT_LABEL_LINE_HORIZONTAL_OFFSET-(DISTANCE_OUTPUT_WIDTH/2))
            labelPositionX+=OUTPUT_LABEL_LINE_HORIZONTAL_OFFSET;
        else
            labelPositionX-=OUTPUT_LABEL_LINE_HORIZONTAL_OFFSET;
    }
    else
    {
        if(labelPositionX<DISTANCE_OUTPUT_WIDTH/2)
            labelPositionX=DISTANCE_OUTPUT_WIDTH/2;
        else if(labelPositionX>deviceFrameWidth-DISTANCE_OUTPUT_WIDTH/2)
            labelPositionX=deviceFrameWidth-DISTANCE_OUTPUT_WIDTH/2;
    }
    return labelPositionX;
}

-(int) getDistanceLabelY{
    int labelPositionY,higherY=0,lowerY=0;
    if(point1.y>point2.y)
    {
        higherY=point1.y;
        lowerY=point2.y;
    }
    else
    {
        higherY=point2.y;
        lowerY=point1.y;
    }
    distanceOutputPositionFlag=NO;
    if(higherY<deviceFrameHeight-(DISTANCE_OUTPUT_HEIGHT/2)-OUTPUT_LABEL_LINE_VERTICAL_OFFSET)
        labelPositionY=higherY+OUTPUT_LABEL_LINE_VERTICAL_OFFSET;
    else if(lowerY>TOP_BAR_HEIGHT+deviceFrameHeight/2)
    {
        if(abs(point1.x-point2.x)>DISTANCE_OUTPUT_WIDTH+MARKER_BUTTON_WIDTH)
            labelPositionY=lowerY-OUTPUT_LABEL_LINE_VERTICAL_OFFSET;
        else
            labelPositionY=lowerY-OUTPUT_LABEL_LINE_VERTICAL_OFFSET-MARKER_BUTTON_HEIGHT;
    }
    else
    {
        labelPositionY=(lowerY+higherY)/2;
        distanceOutputPositionFlag=YES;
    }
    if(abs(point1.y-point2.y)>MARKER_BUTTON_HEIGHT+deviceFrameWidth/3+OUTPUT_LABEL_LINE_VERTICAL_OFFSET)
    {
        labelPositionY=(lowerY+higherY)/2;
        distanceOutputPositionFlag=YES;
        if(abs(point1.y-point2.y)<deviceFrameWidth/2)
            labelPositionY+=OUTPUT_LABEL_LINE_VERTICAL_OFFSET;

    }
    return labelPositionY;
}
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(buttonIndex >= MEASUREMENT_UNITS.count) {
        return;
    }
    currentUnit=buttonIndex;
}






















@end
