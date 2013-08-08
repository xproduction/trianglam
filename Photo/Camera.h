//
//  Camera.h
//  Photo
//
//  Created by Matěj Kašpar Jirásek on 27.11.12.
//  Copyright (c) 2012 X Production s.r.o. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

@protocol CameraDelegate <NSObject>

- (void)cameraTookImage:(UIImage *)image;

@end


@interface Camera : NSObject
{
    AVCaptureSession *session;
    AVCaptureVideoPreviewLayer *videoPreviewLayer;
    AVCaptureStillImageOutput *imageOutput;
    AVCaptureInput *frontCamera, *backCamera;
    NSUInteger cameraCount;
    UIView* cameraContainerView;
    id<CameraDelegate> delegate;
}

@property id<CameraDelegate> delegate;
@property (readonly) NSUInteger cameraCount;

- (void)showPreviewInView:(UIView *)view;
- (void)switchCamera;
- (void)takePicture;
- (BOOL)hasFlash;
- (void)setFlashOn;
- (void)setFlashOff;
- (void)setFlashAuto;

@end
