/*
 A great portion of this code is copied from shared libraries or
 open-source example codes, not for commercial use. Only tested on
 iPhone 5s.
 
 Project Name: Quasi-Mouse
 Created by Ruicheng Xian on July 31, 2014
 For EE 47 Final Project
 
 This Xcode project is the interface on iPhone 5s that controls the
 motors on the remote car, via Bluetooth Low Energy (4.0) protocol.
 
 Reference:
 * Bluefruit LE Connect from Adafruit
    - Open Source Code: http://github.com/adafruit/Bluefruit_LE_Connect
 * Image Resizing by iWasRobbed
    - Open Source Code: http://stackoverflow.com/questions/2658738/the-simplest-way-to-resize-an-uiimage
 
*/


#import "QMViewController.h"
#import "UIImageResizing.h"

#import <QuartzCore/QuartzCore.h>
#import "NSString+hex.h"
#import "NSData+hex.h"


#define NUMBER_OF_SOUNDS 10  // sound file numbers are from 0001.ad4 to 0799.ad4 (799 total)
#define NUMBER_OF_SONGS 5  // song file numbers are from 0800.ad4 to 0999.ad4 (200 total)

#define MAX_VOLUME 7 // maximum volume is 7
#define MIN_VOLUME 4 // minimum volume is 0, but any value below 4 is unstable

#define MAX_SPEED 255  // maximum one way speed is 255, not to be changed
#define NO_SPEED MAX_SPEED  // speed ranges from 0~510, 255 is the median, not to be changed
#define MAX_STEER 150  // maximum steer, no exceeding 255
#define NO_STEER MAX_STEER  // the median of steer


@interface QMViewController ()<UIAlertViewDelegate>{
    // bluetooth variables
    CBCentralManager    *cm;
    UARTPeripheral      *currentPeripheral;
}
@end

@implementation QMViewController
@synthesize verticalSlider, horizontalSlider, connectButton, soundButton, levelOutputTextView, outputTextView, logButton, batteryIndicator, volumeIndicator;

NSTimer *connectionButtonBlinkTimer;  // UI connect button blinking timer
bool connectionButtonBlinkAnimationIsHighlighted = NO;

int musicNumber = 800;  // to distinguish between sound and music, music files are numbered from 800-1000, while sound files are 1-799 in this case
int musicVolume = 4;
int speedValue = NO_SPEED;
int steerValue = NO_STEER;

- (void)viewDidLoad
{
    [super viewDidLoad];

    // setup the UI
    [horizontalSlider setThumbImage:[[UIImage imageNamed:@"h_thumb.png"] scaleToSize:CGSizeMake(75.0f, 40.0f)] forState:UIControlStateNormal];
    [horizontalSlider setMaximumTrackImage:[[[UIImage imageNamed:@"h_slider_track.png"] scaleToSize:CGSizeMake(210.0f, 10.5f)] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)] forState:UIControlStateNormal];
    [horizontalSlider setMinimumTrackImage:[[[UIImage imageNamed:@"h_slider_track.png"] scaleToSize:CGSizeMake(210.0f, 10.5f)] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)] forState:UIControlStateNormal];
    [verticalSlider setThumbImage:[[UIImage imageNamed:@"v_thumb.png"] scaleToSize:CGSizeMake(75.0f, 40.0f)] forState:UIControlStateNormal];
    [verticalSlider setMaximumTrackImage:[[[UIImage imageNamed:@"v_slider_track.png"] scaleToSize:CGSizeMake(210.0f, 10.5f)] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)] forState:UIControlStateNormal];
    [verticalSlider setMinimumTrackImage:[[[UIImage imageNamed:@"v_slider_track.png"] scaleToSize:CGSizeMake(210.0f, 10.5f)] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)] forState:UIControlStateNormal];
    
    // rotate the verticalSlider by 90 degrees counter-clockwise
    /* http://stackoverflow.com/questions/8118033/how-to-change-the-uislider-to-vertical by Antzi */
    UIView *superView = self.verticalSlider.superview;
    [self.verticalSlider removeFromSuperview];
    [self.verticalSlider removeConstraints:self.view.constraints];
    self.verticalSlider.translatesAutoresizingMaskIntoConstraints = YES;
    self.verticalSlider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    [superView addSubview:self.verticalSlider];
    
    // control and log display initialization
    [self slideEvent:nil];
    outputTextView.text = @"";
    
    // bluetooth initialization
    cm = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    _connectionStatus = ConnectionStatusDisconnected;
}


// bluetooth connection functions
- (void)centralManager:(CBCentralManager*)central didDiscoverPeripheral:(CBPeripheral*)peripheral advertisementData:(NSDictionary*)advertisementData RSSI:(NSNumber*)RSSI
{
    
    [self postToOutput:[NSString stringWithFormat:@"Did discover peripheral %@", peripheral.name]];
    
    [cm stopScan];
    
    [self connectPeripheral:peripheral];
}

- (void)centralManager:(CBCentralManager*)central didConnectPeripheral:(CBPeripheral*)peripheral
{
    
    if ([currentPeripheral.peripheral isEqual:peripheral]){
        
        if(peripheral.services){
            [self postToOutput:[NSString stringWithFormat:@"Did connect to existing peripheral %@", peripheral.name]];
            [currentPeripheral peripheral:peripheral didDiscoverServices:nil]; //already discovered services, DO NOT re-discover. Just pass along the peripheral.
        }
        
        else{
            [self postToOutput:[NSString stringWithFormat:@"Did connect peripheral %@", peripheral.name]];
            [currentPeripheral didConnect];
        }
    }
}

- (void)centralManager:(CBCentralManager*)central didDisconnectPeripheral:(CBPeripheral*)peripheral error:(NSError*)error
{
    
    [self postToOutput:[NSString stringWithFormat:@"Did disconnect peripheral %@", peripheral.name]];
    
    //respond to disconnected
    [self peripheralDidDisconnect];
    
    if ([currentPeripheral.peripheral isEqual:peripheral])
    {
        [currentPeripheral didDisconnect];
    }
}

- (void)scanForPeripherals
{
    
    //Look for available Bluetooth LE devices
    
    //skip scanning if UART is already connected
    NSArray *connectedPeripherals = [cm retrieveConnectedPeripheralsWithServices:@[UARTPeripheral.uartServiceUUID]];
    if ([connectedPeripherals count] > 0) {
        //connect to first peripheral in array
        [self connectPeripheral:[connectedPeripherals objectAtIndex:0]];
    }
    
    else{
        
        [cm scanForPeripheralsWithServices:@[UARTPeripheral.uartServiceUUID]
                                   options:@{CBCentralManagerScanOptionAllowDuplicatesKey: [NSNumber numberWithBool:NO]}];
    }
    
    _connectionStatus = ConnectionStatusScanning;
    
}


// bluetooth status functions
- (void)centralManagerDidUpdateState:(CBCentralManager*)central
{
    
    if (central.state == CBCentralManagerStatePoweredOn){
        
        //respond to powered on
    }
    
    else if (central.state == CBCentralManagerStatePoweredOff){
        
        //respond to powered off
        
        _connectionStatus = ConnectionStatusDisconnected;
        
        [self connectButtonStyle];
    }
    
}

- (void)peripheralDidDisconnect
{
    
    //respond to device disconnecting
    
    //if status was connected, then disconnect was unexpected by the user, show alert
    if (_connectionStatus == ConnectionStatusConnected) {
        
        //display disconnect alert
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Disconnected"
                                                       message:@"BLE peripheral has disconnected"
                                                      delegate:nil
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles: nil];
        
        [alert show];
    }
    
    _connectionStatus = ConnectionStatusDisconnected;
    _connectionMode = ConnectionModeNone;
    
    [self connectButtonStyle];
}

- (void)connectPeripheral:(CBPeripheral*)peripheral
{
    
    //Connect Bluetooth LE device
    
    //Clear off any pending connections
    [cm cancelPeripheralConnection:peripheral];
    
    //Connect
    currentPeripheral = [[UARTPeripheral alloc] initWithPeripheral:peripheral delegate:self];
    [cm connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey: [NSNumber numberWithBool:YES]}];
    _connectionStatus = ConnectionStatusConnected;
    
    [self connectButtonStyle];
    batteryIndicator.image = [UIImage imageNamed:@"indicator_b.png"];
    musicNumber = 800;
}

- (void)disconnect
{
    
    //Disconnect Bluetooth LE device
    
    _connectionStatus = ConnectionStatusDisconnected;
    _connectionMode = ConnectionModeNone;
    
    [cm cancelPeripheralConnection:currentPeripheral.peripheral];
    
    [self connectButtonStyle];
}


// bluetooth error functions
- (void)didReadHardwareRevisionString:(NSString*)string
{
    
    //Once hardware revision string is read, connection to Bluefruit is complete
    
    [self postToOutput:[NSString stringWithFormat:@"HW Revision: %@", string]];

    _connectionStatus = ConnectionStatusConnected;
    [self connectButtonStyle];
}

- (void)uartDidEncounterError:(NSString*)error
{
    //Display error alert
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Error"
                                                   message:error
                                                  delegate:nil
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];
    
    [alert show];
    
    _connectionStatus = ConnectionStatusDisconnected;
    [self connectButtonStyle];
}


// bluetooth interaction functions
- (void)didReceiveData:(NSData*)newData
{
    
    // data incoming from UART peripheral, forward to current view controller
    int dataLength = (int)newData.length;
    uint8_t data[dataLength];
    
    [newData getBytes:&data length:dataLength];
    
    for (int i = 0; i<dataLength; i++) {
        
        if ((data[i] <= 0x1f) || (data[i] >= 0x80)) {    //null characters
            if ((data[i] != 0x9) && //0x9 == TAB
                (data[i] != 0xa) && //0xA == NL
                (data[i] != 0xd)) { //0xD == CR
                data[i] = 0xA9;
            }
        }
    }
    
    NSString *newString = [[NSString alloc]initWithBytes:&data
                                                  length:dataLength
                                                encoding:NSUTF8StringEncoding];
    
    [self postToOutput:[NSString stringWithFormat:@"Received: %@", newString]];
    
    if ([newString integerValue] <= 760) {
        batteryIndicator.image = [UIImage imageNamed:@"indicator_r.png"];
    } else if ([newString integerValue] <= 820) {
        batteryIndicator.image = [UIImage imageNamed:@"indicator_y.png"];
    } else {
        batteryIndicator.image = [UIImage imageNamed:@"indicator_b.png"];
    }
    // function not used
}

- (void)sendData:(NSData*)newData
{
    
    //Output data to UART peripheral
    
    
    [currentPeripheral writeRawData:newData];
    
}


// control interaction functions
float lastVerticalValue = 0.5;
float lastHorizontalValue = 0.5;
- (IBAction)slideEvent:(id)sender
{
    if (lastHorizontalValue != (int)(horizontalSlider.value * 10) || lastVerticalValue != (int)(verticalSlider.value * 10)) {  // avoid sending the same value
        lastHorizontalValue = (int)(horizontalSlider.value * 10);
        lastVerticalValue = (int)(verticalSlider.value * 10);
        NSArray *motorSpeeds = [self calculateMotorSpeed:(10-lastVerticalValue)/10 :(lastHorizontalValue)/10];  // inversed because of installation problem
//        NSArray *motorSpeeds = [self calculateMotorSpeed:lastVerticalValue/10 :lastHorizontalValue/10];
        [self sendSignal:[NSString stringWithFormat:@"A%@", [motorSpeeds objectAtIndex:0]]];
        [self sendSignal:[NSString stringWithFormat:@"B%@", [motorSpeeds objectAtIndex:1]]];
        [self postToOutput:@""];
    }
}

- (IBAction)resetSlider:(id)sender
{
    // Reset the sliders to their initial positions at touch up
    /* http://stackoverflow.com/questions/3304646/how-to-know-or-retrieve-the-sender-id */
    if (sender == horizontalSlider) {
        horizontalSlider.value = 0.5;
        [self slideEvent:horizontalSlider]; // Redo the level calculation
    } else {
        verticalSlider.value = 0.5;
        [self slideEvent:verticalSlider]; // Redo the level calculation
    }
}

- (IBAction)connectEvent:(id)sender
{
    [self postToOutput:@"Connect button pressed"];
    if (_connectionStatus == ConnectionStatusScanning) {
        return;
    } else {
        if (_connectionStatus == ConnectionStatusDisconnected) {
            // attempt to connect
            [self scanForPeripherals];
            [self connectButtonStyle];
        } else {
            // end connection
            [self disconnect];
            [self connectButtonStyle];
        }
    }
}

bool canPlaySong = true;  // prevent changing songs too fast
float allowPlayThreshold = 0.05;
- (IBAction)soundEvent:(id)sender
{
    if (_connectionStatus == ConnectionStatusConnected && canPlaySong) {
        [self postToOutput:@"Sound button pressed"];
        int soundNumber = 1 + random() % NUMBER_OF_SOUNDS; // specify max sound number
        [self sendSignal:[NSString stringWithFormat:@"I%d", musicVolume]];
        [self sendSignal:[NSString stringWithFormat:@"S%d", soundNumber]];
        canPlaySong = false;
        [NSTimer scheduledTimerWithTimeInterval:allowPlayThreshold target:self selector:@selector(allowPlaySong) userInfo:nil repeats:NO];
    } else {
        return;
    }
}

- (IBAction)musicEvent:(id)sender
{
    if (_connectionStatus == ConnectionStatusConnected && canPlaySong) {

        [self postToOutput:@"Music button pressed"];
        [self sendSignal:[NSString stringWithFormat:@"I%d", musicVolume]];
        [self sendSignal:[NSString stringWithFormat:@"S%d", musicNumber]];
        musicNumber ++;
        if (musicNumber == 800 + NUMBER_OF_SONGS) { // specify max music number
            musicNumber = 800;
        }
        canPlaySong = false;
        [NSTimer scheduledTimerWithTimeInterval:allowPlayThreshold target:self selector:@selector(allowPlaySong) userInfo:nil repeats:NO];
    } else {
        return;
    }
}

- (void)allowPlaySong
{
    canPlaySong = true;
}

- (IBAction)soundSlientEvent:(id)sender
{
    [self postToOutput:@"Sound button released"];
    
    [self sendSignal:[NSString stringWithFormat:@"N"]];
}

- (IBAction)volumeUpEvent:(id)sender
{
    if (musicVolume == MAX_VOLUME) {
        return;
    } else {
        musicVolume ++;
        [self sendSignal:[NSString stringWithFormat:@"I%d", musicVolume]];
        volumeIndicator.image = [UIImage imageNamed:[NSString stringWithFormat:@"volume_%d.png",musicVolume-1]];
    }
}

- (IBAction)volumeDownEvent:(id)sender
{
    if (musicVolume == MIN_VOLUME) {
        return;
    } else {
        musicVolume --;
        [self sendSignal:[NSString stringWithFormat:@"I%d", musicVolume]];
        volumeIndicator.image = [UIImage imageNamed:[NSString stringWithFormat:@"volume_%d.png",musicVolume-1]];
    }
}


// control and log information processing functions
- (NSArray *)calculateMotorSpeed:(float)rawPowerValue :(float)rawSteerValue
{
    NSMutableArray *calculatedMotorSpeeds = [NSMutableArray arrayWithObjects:[NSNumber numberWithInteger:rawPowerValue * MAX_SPEED * 2], [NSNumber numberWithInteger:rawPowerValue * MAX_SPEED * 2], nil];
    if (rawSteerValue != 0.5) {  // if steer
        int motorASpeed = rawPowerValue * MAX_SPEED * 2;
        int motorBSpeed = motorASpeed;
        if (rawSteerValue < 0.5) {  // if turning to motor A's side
            motorASpeed -= ((0.5 - rawSteerValue) * MAX_STEER * 2);
            motorBSpeed += ((0.5 - rawSteerValue) * MAX_STEER * 2);
            if (motorASpeed < 0) {
                motorBSpeed += (0 - motorASpeed);
                motorASpeed = 0;
            }
            if (motorBSpeed > MAX_SPEED * 2) {
                motorASpeed -= (motorBSpeed - MAX_SPEED * 2);
                motorBSpeed = 510;
            }
        } else {  // if turning to motor B's side
            motorASpeed += ((rawSteerValue - 0.5) * MAX_STEER * 2);
            motorBSpeed -= ((rawSteerValue - 0.5) * MAX_STEER * 2);
            if (motorBSpeed < 0) {
                motorASpeed += (0 - motorBSpeed);
                motorBSpeed = 0;
            }
            if (motorASpeed > MAX_SPEED * 2) {
                motorBSpeed -= (motorASpeed - MAX_SPEED * 2);
                motorASpeed = 510;
            }
        }
        [calculatedMotorSpeeds replaceObjectAtIndex:0 withObject:[NSNumber numberWithInteger:motorASpeed]];
        [calculatedMotorSpeeds replaceObjectAtIndex:1 withObject:[NSNumber numberWithInteger:motorBSpeed]];
    }
    return calculatedMotorSpeeds;
}

- (void)sendSignal:(NSString *)message
{
    if (_connectionStatus == ConnectionStatusConnected) {
        [self postToOutput:[NSString stringWithFormat:@"Sending: %@", message]];
        NSData *data = [NSData dataWithBytes:message.UTF8String length:message.length];
        [self sendData:data];
    }
}

- (void)postToOutput:(NSString *)message
{
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"hh:mm:ss";
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    
    if (![message isEqual:@""]) {
        if ([outputTextView.text isEqualToString:@""]) {
            outputTextView.text = [NSString stringWithFormat:@"[%@] %@",[dateFormatter stringFromDate:now], message];
            
        } else {
            outputTextView.text = [NSString stringWithFormat:@"[%@] %@\n%@",[dateFormatter stringFromDate:now], message, outputTextView.text];
        }
    } else {
        levelOutputTextView.text = [NSString stringWithFormat:@"[%@] V:%1.2f H:%1.2f",[dateFormatter stringFromDate:now],verticalSlider.value, horizontalSlider.value];
    }
}

- (IBAction)displayLog:(id)sender
{
    if (outputTextView.hidden == YES) {
        outputTextView.hidden = NO;
        levelOutputTextView.hidden = NO;
        [logButton setImage:[UIImage imageNamed:@"u_h_log.png"] forState:UIControlStateNormal];
        [logButton setImage:[UIImage imageNamed:@"p_h_log.png"] forState:UIControlStateHighlighted];
    } else {
        outputTextView.hidden = YES;
        levelOutputTextView.hidden = YES;
        [logButton setImage:[UIImage imageNamed:@"u_log.png"] forState:UIControlStateNormal];
        [logButton setImage:[UIImage imageNamed:@"p_log.png"] forState:UIControlStateHighlighted];
    }
    
    
}

- (void)connectButtonStyle
{
    if (_connectionStatus == ConnectionStatusDisconnected) {
        [connectionButtonBlinkTimer invalidate];
        connectionButtonBlinkAnimationIsHighlighted = NO;
        [connectButton setImage:[[UIImage imageNamed:@"u_link.png"] scaleToSize:CGSizeMake(50.0f, 50.0f)] forState:UIControlStateNormal];
        [connectButton setImage:[[UIImage imageNamed:@"p_link.png"] scaleToSize:CGSizeMake(50.0f, 50.0f)] forState:UIControlStateHighlighted];
        batteryIndicator.image = [UIImage imageNamed:@"indicator_n.png"];
    } else if (_connectionStatus == ConnectionStatusConnected) {
        [connectionButtonBlinkTimer invalidate];
        connectionButtonBlinkAnimationIsHighlighted = NO;
        [connectButton setImage:[[UIImage imageNamed:@"u_h_link.png"] scaleToSize:CGSizeMake(50.0f, 50.0f)] forState:UIControlStateNormal];
        [connectButton setImage:[[UIImage imageNamed:@"p_h_link.png"] scaleToSize:CGSizeMake(50.0f, 50.0f)] forState:UIControlStateHighlighted];
    } else if (_connectionStatus == ConnectionStatusScanning) {
        connectionButtonBlinkTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(connectButtonBlink) userInfo:nil repeats:YES];
    }
}

- (void)connectButtonBlink
{
    if (connectionButtonBlinkAnimationIsHighlighted) {
        [connectButton setImage:[[UIImage imageNamed:@"u_link.png"] scaleToSize:CGSizeMake(50.0f, 50.0f)] forState:UIControlStateNormal];
        [connectButton setImage:[[UIImage imageNamed:@"p_link.png"] scaleToSize:CGSizeMake(50.0f, 50.0f)] forState:UIControlStateHighlighted];
        connectionButtonBlinkAnimationIsHighlighted = NO;
    } else {
        [connectButton setImage:[[UIImage imageNamed:@"u_h_link.png"] scaleToSize:CGSizeMake(50.0f, 50.0f)] forState:UIControlStateNormal];
        [connectButton setImage:[[UIImage imageNamed:@"p_h_link.png"] scaleToSize:CGSizeMake(50.0f, 50.0f)] forState:UIControlStateHighlighted];
        connectionButtonBlinkAnimationIsHighlighted = YES;
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
