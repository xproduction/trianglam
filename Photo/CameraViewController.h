//
//  CameraViewController.h
//  Photo
//
//  Created by Matěj Kašpar Jirásek on 27.11.12.
//  Copyright (c) 2012 X Production s.r.o. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "Camera.h"
#import "DropDown.h"
#import "CDActivityIndicatorView.h"
#import "Gallery.h"

@interface CameraViewController : UIViewController<CameraDelegate, DropDownDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate>
{
    UIView *cameraView, *lightView;
    UIImageView *pictureView, *processedView;
    UIImage *processedImage, *thumbImage;
    NSMutableArray *queue;
    CDActivityIndicatorView *indicatorView;
    Camera *camera;
    Gallery *gallery;
    UIButton *galleryButton, *takePictureButton, *okButton, *notOkButton, *chooseFromGallery, *switchButton;
    NSUInteger processing, size;
    NSString *vector;
    DropDown *flashDropDown, *sizeDropDown, *shapeDropDown;
    NSUInteger shape;
    UIPopoverController* popover;
    CLLocation* pictureLocation;
    CLLocationManager* locationManager;
}

@property (nonatomic, strong) UIButton* galleryButton;

@end
