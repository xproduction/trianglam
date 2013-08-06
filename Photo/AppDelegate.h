//
//  AppDelegate.h
//  Photo
//
//  Created by Matěj Kašpar Jirásek on 27.11.12.
//  Copyright (c) 2012 X Production s.r.o. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "CameraViewController.h"
#import "GalleryViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    CameraViewController *cameraController;
    GalleryViewController *galleryController;
    
    BOOL automaticallySaveToCameraRoll;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) CameraViewController *cameraController;

@property BOOL automaticallySaveToCameraRoll;

- (void)transitionToGallery;
- (void)transitionToCamera;

@end
