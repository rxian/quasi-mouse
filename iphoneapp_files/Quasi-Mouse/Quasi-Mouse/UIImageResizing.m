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

#import "UIImageResizing.h"

@implementation UIImage (Resize)

- (UIImage*)scaleToSize:(CGSize)size {
    //UIGraphicsBeginImageContext(size);
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        if ([[UIScreen mainScreen] scale] == 2.0) {
            UIGraphicsBeginImageContextWithOptions(size, NO, 2.0);
        } else {
            UIGraphicsBeginImageContext(size);
        }
    } else {
        UIGraphicsBeginImageContext(size);
    }
    
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0.0, size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, size.width, size.height), self.CGImage);
    
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

@end