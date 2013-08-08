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

@interface CameraViewController : UIViewController<CameraDelegate, DropDownDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    UIView *cameraView, *lightView;
    UIImageView *pictureView, *processedView;
    UIImage *processedImage, *thumbImage;
    NSMutableArray *queue;
    UIActivityIndicatorView *indicatorView;
    Camera *camera;
    UIButton *galleryButton, *takePictureButton, *okButton, *notOkButton, *chooseFromGallery, *switchButton;
    NSUInteger processing, size;
    NSString *vector;
    DropDown *flashDropDown, *sizeDropDown, *shapeDropDown;
    NSUInteger shape;
    UIPopoverController* popover;
}

@property (nonatomic, strong) UIButton* galleryButton;

@end
