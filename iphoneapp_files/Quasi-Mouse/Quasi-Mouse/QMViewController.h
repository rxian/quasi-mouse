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


#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "UARTPeripheral.h"


@interface QMViewController : UIViewController <CBCentralManagerDelegate, UARTPeripheralDelegate> {
    // control UI
    IBOutlet UISlider *verticalSlider;
    IBOutlet UISlider *horizontalSlider;
    IBOutlet UIButton *connectButton;
    IBOutlet UIButton *soundButton;
    
    // log display UI
    IBOutlet UITextView *levelOutputTextView;
    IBOutlet UITextView *outputTextView;
    IBOutlet UIButton *logButton;
    IBOutlet UIImageView *batteryIndicator;
    IBOutlet UIImageView *volumeIndicator;
}


// bluetooth variables
typedef enum {
    ConnectionModeNone  = 0,
    ConnectionModePinIO,
    ConnectionModeUART,
} ConnectionMode;

typedef enum {
    ConnectionStatusDisconnected = 0,
    ConnectionStatusScanning,
    ConnectionStatusConnected,
} ConnectionStatus;

@property (nonatomic, assign) ConnectionMode connectionMode;
@property (nonatomic, assign) ConnectionStatus connectionStatus;


// control UI
@property (nonatomic, retain) UISlider *verticalSlider;
@property (nonatomic, retain) UISlider *horizontalSlider;
@property (nonatomic, retain) UIButton *connectButton;
@property (nonatomic, retain) UIButton *soundButton;

// log display UI
@property (nonatomic, retain) UITextView *levelOutputTextView;
@property (nonatomic, retain) UITextView *outputTextView;
@property (nonatomic, retain) UIButton *logButton;
@property (nonatomic, retain) UIImageView *batteryIndicator;
@property (nonatomic, retain) UIImageView *volumeIndicator;


// control functions
- (IBAction)slideEvent:(id)sender;
- (IBAction)resetSlider:(id)sender;
- (IBAction)connectEvent:(id)sender;
- (IBAction)soundEvent:(id)sender;
- (IBAction)soundSlientEvent:(id)sender;
- (IBAction)musicEvent:(id)sender;
- (IBAction)volumeUpEvent:(id)sender;
- (IBAction)volumeDownEvent:(id)sender;

// log display function
- (IBAction)displayLog:(id)sender;

@end
