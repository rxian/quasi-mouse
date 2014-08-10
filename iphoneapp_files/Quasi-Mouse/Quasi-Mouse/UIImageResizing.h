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


@interface UIImage (Resize)
- (UIImage*)scaleToSize:(CGSize)size;
@end