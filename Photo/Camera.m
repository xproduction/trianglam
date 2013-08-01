//
//  Camera.m
//  Photo
//
//  Created by Matěj Kašpar Jirásek on 27.11.12.
//  Copyright (c) 2012 X Production s.r.o. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>

#import "Camera.h"

@implementation Camera

@synthesize delegate;
@synthesize cameraCount;

- (id)init
{
    self = [super init];
    if(self)
    {
        [self startSession];
    }
    return self;
}

- (BOOL)hasFlash
{
    AVCaptureDevice *device = [self getActualInput];
    if(device != nil)
    {
        return [device hasFlash];
    }
    return NO;
}

- (void)setFlashOn
{
    [self setFlashMode:AVCaptureFlashModeOn];
}

- (void)setFlashOff
{
    [self setFlashMode:AVCaptureFlashModeOff];
}

- (void)setFlashAuto
{
    [self setFlashMode:AVCaptureFlashModeAuto];
}
         
- (void)setFlashMode:(AVCaptureFlashMode)mode
{
    AVCaptureDevice *device = [self getActualInput];
    if ([device hasFlash])
    {
        NSError *error = nil;
        [device lockForConfiguration:&error];
        if(error != nil)
        {
            NSLog(@"%@", error);
            return;
        }
        device.flashMode = mode;
        [device unlockForConfiguration];
    }
}

- (void)takePicture
{
    AVCaptureConnection *connection = nil;
    for (AVCaptureConnection *con in imageOutput.connections) {
        for (AVCaptureInputPort *port in [con inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                connection = con;
                break;
            }
        }
        if (connection)
        {
            break;
        }
    }
    
    [imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:
     ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
         if (error != nil) {
             NSLog(@"%@", error);
             return;
         }
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         UIImage *image = [[UIImage alloc] initWithData:imageData];
         [delegate cameraTookImage:image];
     }];
}
         
- (AVCaptureDevice *)getActualInput
{
    [self setUpSession];
    if (session.inputs.count > 0) {
        AVCaptureDeviceInput *input = [session.inputs objectAtIndex:0];
        return input.device;
    }
    return nil;
}

- (void)setUpSession
{
    if(session == nil)
    {
        cameraCount = 0;
        session = [[AVCaptureSession alloc] init];
        session.sessionPreset = AVCaptureSessionPreset640x480;
        
        NSError *error = nil;
        backCamera = [AVCaptureDeviceInput deviceInputWithDevice:[self backFacingCamera] error:&error];
        if(backCamera)
        {
            cameraCount++;
            [session addInput:backCamera];
        }
        else
        {
            NSLog(@"%@", error);
        }
        frontCamera = [AVCaptureDeviceInput deviceInputWithDevice:[self frontFacingCamera] error:&error];
        if(frontCamera)
        {
            cameraCount++;
            if([session canAddInput:frontCamera])
            {
                [session addInput:frontCamera];
            }
        }
        else if(error != nil)
        {
            NSLog(@"%@", error);
        }
        imageOutput = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
        [imageOutput setOutputSettings:outputSettings];
        if([session canAddOutput:imageOutput])
        {
            [session addOutput:imageOutput];
        }
        else
        {
            cameraCount = 0;
            NSLog(@"Couldn't add still image output");
        }
        if (cameraCount == 0)
        {
            NSLog(@"no camera found");
        }
    }

}

- (void)startSession
{
    [self setUpSession];
    
    if(!session.running && cameraCount > 0)
    {
        [session startRunning];
    }
}

- (void)showPreviewInView:(UIView *)view
{
    [session stopRunning];
    if (cameraCount == 0) {
        return;
    }
    AVCaptureVideoPreviewLayer *videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [view.layer setMasksToBounds:YES];
    
    [videoPreviewLayer setFrame:view.bounds];
    
    [videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    [view.layer insertSublayer:videoPreviewLayer below:[[view.layer sublayers] objectAtIndex:0]];
    [session startRunning];
}

- (void)switchCamera
{
    if (cameraCount > 1) {
        [session beginConfiguration];
        if([session.inputs containsObject:frontCamera])
        {
            [session removeInput:frontCamera];
            [session addInput:backCamera];
        }
        else
        {
            [session removeInput:backCamera];
            [session addInput:frontCamera];
        }
        [session commitConfiguration];
    }
}

#pragma mark - Utility methods

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (AVCaptureDevice *)frontFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

- (AVCaptureDevice *)backFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

@end
