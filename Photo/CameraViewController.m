//
//  CameraViewController.m
//  Photo
//
//  Created by Matěj Kašpar Jirásek on 27.11.12.
//  Copyright (c) 2012 X Production s.r.o. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "CameraViewController.h"
#import "AppDelegate.h"
#import "Gallery.h"
#import "DropDown.h"
#import "UIImage+Triangles.h"
#import "UIImage+Extensions.h"
#import "AMBlurView.h"

#define BUTTON_FLASH_SIZE 50.0
#define BUTTON_FLASH_PADDING_SIDE 10.0
#define BUTTON_FLASH_PADDING_TOP 5.0

#define BOTTOM_BAR_PADDING 15.0

#define TRINGULAR_PADDING 20.0
#define THUMB_SIZE 200.0

#define SHAPE_TRIANGLE 0
#define SHAPE_RECT 1
#define SHAPE_HEXAGON 2

@interface CameraViewController ()

@end

@implementation CameraViewController

@synthesize galleryButton;

- (id)init
{
    self = [super init];
    if(self)
    {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
        {
            [self setNeedsStatusBarAppearanceUpdate];
        } else {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
            self.wantsFullScreenLayout = YES;
        }
        
        queue = [[NSMutableArray alloc] init];
        
        camera = [[Camera alloc] init];
        camera.delegate = self;
        
        CGRect cameraFrame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
        
        // default settings
        size = 20;
        
        // camera view/layer
        cameraView = [[UIView alloc] initWithFrame:cameraFrame];
        //cameraView.center = self.view.center;
        [self.view addSubview:cameraView];
        
        // picture preview
        pictureView = [[UIImageView alloc] initWithFrame:cameraFrame];
        pictureView.center = self.view.center;
        pictureView.alpha = 0.0;
        pictureView.contentMode = UIViewContentModeScaleAspectFill;
        pictureView.layer.masksToBounds = YES;
        [self.view addSubview:pictureView];
        
        
        // ui sweetness
        CGRect topBlurFrame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.center.y - self.view.frame.size.width / 2.0);
        CGRect bottomBlurFrame = CGRectMake(0.0, self.view.center.y + self.view.frame.size.width / 2.0, self.view.frame.size.width, self.view.center.y - self.view.frame.size.width / 2.0);
        UIColor *blurTintColor = [UIColor colorWithWhite:0.2 alpha:0.6];
        
        AMBlurView *topBlurView = [[AMBlurView alloc] initWithFrame:topBlurFrame];
        topBlurView.blurTintColor = blurTintColor;
        [self.view addSubview:topBlurView];
        
        AMBlurView *bottomBlurView = [[AMBlurView alloc] initWithFrame:bottomBlurFrame];
        bottomBlurView.blurTintColor = blurTintColor;
        [self.view addSubview:bottomBlurView];
        
        // processed view
        CGRect processedViewRect = CGRectMake(0.0, self.view.center.y - self.view.frame.size.width / 2.0, self.view.frame.size.width, self.view.frame.size.width);
        processedView = [[UIImageView alloc] initWithFrame:processedViewRect];
        processedView.center = self.view.center;
        processedView.alpha = 0.0;
        processedView.contentMode = UIViewContentModeScaleAspectFill;
        processedView.layer.masksToBounds = YES;
        [self.view addSubview:processedView];
        
        // buttons
        if(camera.cameraCount > 1)
        {
            switchButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - BUTTON_FLASH_PADDING_SIDE - BUTTON_FLASH_SIZE, self.view.frame.size.height / 2.0 - self.view.frame.size.width / 2.0 - BUTTON_FLASH_PADDING_TOP - BUTTON_FLASH_SIZE, BUTTON_FLASH_SIZE, BUTTON_FLASH_SIZE)];
            [switchButton setImage:[UIImage imageNamed:@"trianglam_switch.png"] forState:UIControlStateNormal];
            [switchButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
            [self.view addSubview:switchButton];
        }
        
        CGRect galleryButtonFrame = CGRectMake(BOTTOM_BAR_PADDING, self.view.frame.size.height - BOTTOM_BAR_HEIGHT + BOTTOM_BAR_PADDING, BOTTOM_BAR_HEIGHT - 2.0 * BOTTOM_BAR_PADDING, BOTTOM_BAR_HEIGHT - 2.0 * BOTTOM_BAR_PADDING);
        galleryButton = [[UIButton alloc] initWithFrame:galleryButtonFrame];
        NSUInteger imageCount = [[Gallery getImageArray] count];
        if(imageCount == 0)
        {
            galleryButton.alpha = 0.0;
        }
        else
        {
            [galleryButton setImage:[Gallery getThumbAtIndex:imageCount - 1] forState:UIControlStateNormal];
        }
        [galleryButton addTarget:self action:@selector(goToGallery:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:galleryButton];
        
        indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicatorView.frame = CGRectMake(self.view.frame.size.width / 2.0 - BOTTOM_BAR_HEIGHT / 2.0, self.view.frame.size.height - BOTTOM_BAR_HEIGHT, BOTTOM_BAR_HEIGHT, BOTTOM_BAR_HEIGHT);
        indicatorView.alpha = 0.0;
        [indicatorView stopAnimating];
        [self.view addSubview:indicatorView];
        
        if(camera.cameraCount != 0)
        {
            takePictureButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2.0 - BOTTOM_BAR_HEIGHT / 2.0, self.view.frame.size.height - BOTTOM_BAR_HEIGHT, BOTTOM_BAR_HEIGHT, BOTTOM_BAR_HEIGHT)];
            [takePictureButton setImage:[UIImage imageNamed:@"Camera.png"] forState:UIControlStateNormal];
            [takePictureButton setImage:[UIImage imageNamed:@"CameraTouched.png"] forState:UIControlStateHighlighted];
            [takePictureButton addTarget:self action:@selector(takePicture:) forControlEvents:UIControlEventTouchUpInside];
            [self.view addSubview:takePictureButton];
            [camera showPreviewInView:cameraView];
        }
        
        chooseFromGallery = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - BOTTOM_BAR_HEIGHT + BOTTOM_BAR_PADDING, self.view.frame.size.height - BOTTOM_BAR_HEIGHT + BOTTOM_BAR_PADDING, BOTTOM_BAR_HEIGHT - 2.0 * BOTTOM_BAR_PADDING, BOTTOM_BAR_HEIGHT - 2.0 * BOTTOM_BAR_PADDING)];
        //[chooseFromGallery setTitle:@"Gal" forState:UIControlStateNormal];
        [chooseFromGallery setImage:[UIImage imageNamed:@"trianglam_gallery.png"] forState:UIControlStateNormal];
        [chooseFromGallery addTarget:self action:@selector(chooseFromGallery:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:chooseFromGallery];
        
        // lightning
        lightView = [[UIView alloc] initWithFrame:cameraFrame];
        lightView.center = self.view.center;
        lightView.alpha = 0.0;
        lightView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:lightView];
        
        // ok/not ok button
        CGRect okButtonFrame = CGRectMake(self.view.frame.size.width / 2.0 + BUTTON_FLASH_PADDING_SIDE / 2.0, self.view.frame.size.height - BOTTOM_BAR_HEIGHT + BOTTOM_BAR_PADDING, BOTTOM_BAR_HEIGHT - 2.0 * BOTTOM_BAR_PADDING, BOTTOM_BAR_HEIGHT - 2.0 * BOTTOM_BAR_PADDING);
        okButton = [[UIButton alloc] initWithFrame:okButtonFrame];
        [okButton setImage:[UIImage imageNamed:@"trianglam_ok.png"] forState:UIControlStateNormal];
        okButton.alpha = 0.0;
        [okButton addTarget:self action:@selector(acceptImage:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:okButton];
        
        CGRect notOkButtonFrame = CGRectMake(self.view.frame.size.width / 2.0 - BOTTOM_BAR_HEIGHT + BUTTON_FLASH_PADDING_SIDE, self.view.frame.size.height - BOTTOM_BAR_HEIGHT + BOTTOM_BAR_PADDING, BOTTOM_BAR_HEIGHT - 2.0 * BOTTOM_BAR_PADDING, BOTTOM_BAR_HEIGHT - 2.0 * BOTTOM_BAR_PADDING);
        notOkButton = [[UIButton alloc] initWithFrame:notOkButtonFrame];
        [notOkButton setImage:[UIImage imageNamed:@"trianglam_close.png"] forState:UIControlStateNormal];
        notOkButton.alpha = 0.0;
        [notOkButton addTarget:self action:@selector(releaseImage:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:notOkButton];
        
        // flash dropdown
        flashDropDown = [[DropDown alloc] initWithFrame:CGRectMake(self.view.frame.size.width - BUTTON_FLASH_PADDING_SIDE * 2.0 - BUTTON_FLASH_SIZE * 2.0, self.view.frame.size.height / 2.0 - self.view.frame.size.width / 2.0 - BUTTON_FLASH_PADDING_TOP - BUTTON_FLASH_SIZE, BUTTON_FLASH_SIZE, BUTTON_FLASH_SIZE)];
        [self.view addSubview:flashDropDown];
        
        UIButton *flashAutoButton = [[UIButton alloc] init];
        [flashAutoButton setImage:[UIImage imageNamed:@"FlashAuto.png"] forState:UIControlStateNormal];
        
        UIButton *flashOnButton = [[UIButton alloc] init];
        [flashOnButton setImage:[UIImage imageNamed:@"Flash.png"] forState:UIControlStateNormal];
        
        UIButton *flashOffButton = [[UIButton alloc] init];
        [flashOffButton setImage:[UIImage imageNamed:@"FlashNo.png"] forState:UIControlStateNormal];
        
        flashDropDown.buttons = @[flashAutoButton, flashOnButton, flashOffButton];
        flashDropDown.delegate = self;
        if ([[NSUserDefaults standardUserDefaults] valueForKey:@"flashPreset"])
            flashDropDown.selectedButtonIndex = [[[NSUserDefaults standardUserDefaults] valueForKey:@"flashPreset"] intValue];
        [flashDropDown addTarget:self action:@selector(setFlash:) forControlEvents:UIControlEventTouchUpInside];
        
        // settings
        sizeDropDown = [[DropDown alloc] initWithFrame:CGRectMake(BUTTON_FLASH_PADDING_SIDE * 2.0 + BUTTON_FLASH_SIZE, self.view.frame.size.height / 2.0 - self.view.frame.size.width / 2.0 - BUTTON_FLASH_PADDING_TOP - BUTTON_FLASH_SIZE, BUTTON_FLASH_SIZE, BUTTON_FLASH_SIZE)];
        [self.view addSubview:sizeDropDown];
        
        UIFont *font = [UIFont systemFontOfSize:32.0];
        UIButton *smallSizeButton = [[UIButton alloc] init];
        [smallSizeButton setTitle:@"S" forState:UIControlStateNormal];
        smallSizeButton.titleLabel.font = font;
        [smallSizeButton setTitleColor:[UIColor colorWithWhite:0.9 alpha:0.5] forState:UIControlStateHighlighted];
        
        UIButton *middleSizeButton = [[UIButton alloc] init];
        [middleSizeButton setTitle:@"M" forState:UIControlStateNormal];
        middleSizeButton.titleLabel.font = font;
        [middleSizeButton setTitleColor:[UIColor colorWithWhite:0.9 alpha:0.5] forState:UIControlStateHighlighted];
        
        UIButton *largeSizeButton = [[UIButton alloc] init];
        [largeSizeButton setTitle:@"L" forState:UIControlStateNormal];
        largeSizeButton.titleLabel.font = font;
        [largeSizeButton setTitleColor:[UIColor colorWithWhite:0.9 alpha:0.5] forState:UIControlStateHighlighted];
        
        sizeDropDown.buttons = @[smallSizeButton, middleSizeButton, largeSizeButton];
        sizeDropDown.delegate = self;
        [sizeDropDown addTarget:self action:@selector(setSize:) forControlEvents:UIControlEventTouchUpInside];
        if ([[NSUserDefaults standardUserDefaults] valueForKey:@"sizePreset"])
            sizeDropDown.selectedButtonIndex = [[[NSUserDefaults standardUserDefaults] valueForKey:@"sizePreset"] intValue];
        else
            sizeDropDown.selectedButtonIndex = 1;
    
        // shape dropdown
        shapeDropDown = [[DropDown alloc] initWithFrame:CGRectMake(BUTTON_FLASH_PADDING_SIDE, self.view.frame.size.height / 2.0 - self.view.frame.size.width / 2.0 - BUTTON_FLASH_PADDING_TOP - BUTTON_FLASH_SIZE, BUTTON_FLASH_SIZE, BUTTON_FLASH_SIZE)];
        [self.view addSubview:shapeDropDown];
        
        UIButton *triangleButton = [[UIButton alloc] init];
        [triangleButton setImage:[UIImage imageNamed:@"trianglam_triangle_icon.png"] forState:UIControlStateNormal];
        
        UIButton *squareButton = [[UIButton alloc] init];
        [squareButton setImage:[UIImage imageNamed:@"Rectangle.png"] forState:UIControlStateNormal];
        
        UIButton *hexagonButton = [[UIButton alloc] init];
        [hexagonButton setImage:[UIImage imageNamed:@"Hexagon.png"] forState:UIControlStateNormal];
        
        shapeDropDown.buttons = @[triangleButton, squareButton, hexagonButton];
        shapeDropDown.delegate = self;
        [shapeDropDown addTarget:self action:@selector(setShape:) forControlEvents:UIControlEventTouchUpInside];
        if ([[NSUserDefaults standardUserDefaults] valueForKey:@"shapePreset"])
            shapeDropDown.selectedButtonIndex = [[[NSUserDefaults standardUserDefaults] valueForKey:@"shapePreset"] intValue];

        [self reloadUserInterface];
    }
    return self;
}

- (void)viewDidLoad
{

}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)reloadUserInterface
{
    if ([camera hasFlash])
    {
        flashDropDown.hidden = NO;
    }
    else
    {
        flashDropDown.hidden = YES;
    }
}

#pragma mark - Outlets

- (IBAction)takePicture:(id)sender
{
    [camera takePicture];
}

- (IBAction)chooseFromGallery:(id)sender
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    if(IS_IPAD)
    {
        picker.modalInPopover = YES;
    }
    [self presentViewController:picker animated:YES completion:NULL];
}

- (IBAction)setFlash:(DropDown *)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:sender.selectedButtonIndex] forKey:@"flashPreset"];
    
    [self reloadUserInterface];
    switch (sender.selectedButtonIndex) {
        case 0:
            [camera setFlashAuto];
            break;
        case 1:
            [camera setFlashOn];
            break;
        case 2:
            [camera setFlashOff];
            break;
    }
}

- (IBAction)setSize:(DropDown *)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:sender.selectedButtonIndex] forKey:@"sizePreset"];

    switch (sender.selectedButtonIndex) {
        case 0:
            size = 10;
            break;
        case 1:
            size = 20;
            break;
        case 2:
            size = 35;
            break;
    }
}

- (IBAction)setShape:(DropDown *)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:sender.selectedButtonIndex] forKey:@"shapePreset"];

    shape = sender.selectedButtonIndex;
}

- (IBAction)switchCamera:(id)sender
{
    [camera switchCamera];
    [self reloadUserInterface];
}

- (IBAction)goToGallery:(id)sender
{
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate transitionToGallery];
}

#pragma mark - CameraDelegate

- (void)cameraTookImage:(UIImage *)image
{
    pictureView.image = image;
    pictureView.alpha = 1.0;
    
    [self animateFlash];
    [self tryProcessing:image];
}

- (void)tryProcessing:(UIImage *)image
{
    if (processing > 1) {
        [self performSelector:@selector(tryProcessing:) withObject:image afterDelay:0.1];
    }
    else
    {
        [self performSelectorInBackground:@selector(processImage:) withObject:image];
    }
}

- (void)processImage:(UIImage *)image
{
    [self performSelectorOnMainThread:@selector(startProcessing) withObject:nil waitUntilDone:YES];
    NSDictionary *dic;
    switch (shape) {
        case SHAPE_TRIANGLE:
            dic = [[[image imageByScalingProportionallyToSize:CGSizeMake(480.0, 640.0)] imageAtRect:CGRectMake(0.0, 80.0, 480.0, 480.0)] triangleImageWithWidth:size ratio:4];
            break;
        case SHAPE_RECT:
            dic = [[[image imageByScalingProportionallyToSize:CGSizeMake(480.0, 640.0)] imageAtRect:CGRectMake(0.0, 80.0, 480.0, 480.0)] squareImageWithWidth:size ratio:4];
            break;
        case SHAPE_HEXAGON:
            dic = [[[image imageByScalingProportionallyToSize:CGSizeMake(480.0, 640.0)] imageAtRect:CGRectMake(0.0, 80.0, 480.0, 480.0)] hexagonImageWithWidth:size ratio:4];
            break;
            
    }
    UIImage *tempImage = [dic objectForKey:@"image"];
    NSUInteger padding = (size > 30) ? size * 2.0 : size;
    processedImage = [tempImage imageAtRect:CGRectMake(padding, padding, tempImage.size.width - padding * 2.0, tempImage.size.height - padding * 2.0)];
    thumbImage = [processedImage imageByScalingToSize:CGSizeMake(THUMB_SIZE, THUMB_SIZE)];
    vector = [dic objectForKey:@"vector"];
    [self performSelectorOnMainThread:@selector(stopProcessing) withObject:nil waitUntilDone:YES];
}

#pragma mark - Drop down delegate
- (void)dropDownOpened:(id)dropDown
{
    if(flashDropDown != dropDown)
        [flashDropDown shut];
    if(sizeDropDown != dropDown)
        [sizeDropDown shut];
    if(shapeDropDown != dropDown)
        [shapeDropDown shut];
}

- (void)dropDownShut:(id)dropDown
{
    
}

#pragma mark - Animations

- (void)animateFlash
{
    lightView.alpha = 1.0;
    [UIView animateWithDuration:0.4 animations:^(void){
        lightView.alpha = 0.0;
    } completion:NULL];
}

- (void)startProcessing
{
    processing++;
    [indicatorView startAnimating];
    takePictureButton.alpha = 0.0;
    chooseFromGallery.alpha = 0.0;
    indicatorView.alpha = 1.0;
    galleryButton.alpha = 0.0;
    flashDropDown.alpha = 0.0;
    sizeDropDown.alpha = 0.0;
    shapeDropDown.alpha = 0.0;
    switchButton.alpha = 0.0;
}

- (void)stopProcessing
{
    processing--;
    if (processing == 0) {
        processedView.image = processedImage;
        [UIView animateWithDuration:0.5 animations:^(void){
            processedView.alpha = 1.0;
            indicatorView.alpha = 0.0;
            okButton.alpha = 1.0;
            notOkButton.alpha = 1.0;
        } completion:^(BOOL finished) {
            [indicatorView stopAnimating];
        }];
        
    }
}

- (IBAction)acceptImage:(id)sender
{
    notOkButton.alpha = 0.0;
    okButton.alpha = 0.0;
    pictureView.alpha = 0.0;
    if([Gallery addImage:processedImage thumb:thumbImage vector:vector])
    {
        NSLog(@"image saved");
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Couldn't save your photo", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
    }
    
    CGRect processedImageViewFrame = processedView.frame;
    
    [UIView animateWithDuration:0.4 animations:^(void){
        processedView.frame = galleryButton.frame;
    } completion:^(BOOL finished){
        galleryButton.alpha = 1.0;
        [galleryButton setImage:thumbImage forState:UIControlStateNormal];
        processedView.frame = processedImageViewFrame;
        [self releaseImage:sender];
    }];
}

- (IBAction)releaseImage:(id)sender
{
    notOkButton.alpha = 0.0;
    okButton.alpha = 0.0;
    takePictureButton.alpha = 1.0;
    pictureView.alpha = 0.0;
    processedView.alpha = 0.0;
    chooseFromGallery.alpha = 1.0;
    sizeDropDown.alpha = 1.0;
    flashDropDown.alpha = 1.0;
    shapeDropDown.alpha = 1.0;
    switchButton.alpha = 1.0;
    pictureView.image = nil;
    processedView.image = nil;
    if ([[Gallery getImageArray] count] > 0) {
        galleryButton.alpha = 1.0;
    }
}

#pragma mark - UIImagePickerController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [self cameraTookImage:[image imageByScalingProportionallyToMinimumSize:CGSizeMake(480.0, 480.0)]];
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

@end
