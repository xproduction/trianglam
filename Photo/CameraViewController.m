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

#define BUTTON_FLASH_SIZE 50.0
#define BUTTON_FLASH_PADDING_SIDE 10.0
#define BUTTON_FLASH_PADDING_TOP 15.0

#define BOTTOM_BAR_PADDING 15.0

#define TRINGULAR_PADDING 20.0
#define THUMB_SIZE 200.0

#define SHAPE_TRIANGLE 0
#define SHAPE_RECT 1
#define SHAPE_HEXAGON 2

@interface CameraViewController ()

@end

@implementation CameraViewController

- (id)init
{
    self = [super init];
    if(self)
    {
        queue = [[NSMutableArray alloc] init];
        
        camera = [[Camera alloc] init];
        camera.delegate = self;
        
        CGRect cameraFrame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.width);
        
        // default settings
        size = 20;
        
        // ui sweetness
        
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = self.view.frame;
        gradient.colors = @[(id)[UIColor colorWithWhite:0.1 alpha:1.0].CGColor, (id)[UIColor colorWithWhite:0.5 alpha:1.0].CGColor, (id)[UIColor colorWithWhite:0.1 alpha:1.0].CGColor];
        [self.view.layer addSublayer:gradient];
        
        UIView *cameraShadow = [[UIView alloc] initWithFrame:cameraFrame];
        cameraShadow.center = self.view.center;
        cameraShadow.layer.shadowOffset = CGSizeMake(0, 0);
        cameraShadow.layer.shadowOpacity = 0.9;
        cameraShadow.layer.shadowRadius = 8;
        cameraShadow.layer.shadowColor = [UIColor blackColor].CGColor;
        cameraShadow.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:cameraShadow];
        
        // camera view/layer
        cameraView = [[UIView alloc] initWithFrame:cameraFrame];
        cameraView.center = self.view.center;
        [self.view addSubview:cameraView];
        
        
        // buttons
        if(camera.cameraCount > 1)
        {
            switchButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - BUTTON_FLASH_PADDING_SIDE - BUTTON_FLASH_SIZE, self.view.frame.size.height / 2.0 - self.view.frame.size.width / 2.0 - BUTTON_FLASH_PADDING_TOP - BUTTON_FLASH_SIZE, BUTTON_FLASH_SIZE, BUTTON_FLASH_SIZE)];
            [switchButton setImage:[UIImage imageNamed:@"trianglam_switch.png"] forState:UIControlStateNormal];
            switchButton.layer.shadowOffset = CGSizeMake(0, 0);
            switchButton.layer.shadowOpacity = 0.9;
            switchButton.layer.shadowRadius = 6;
            switchButton.layer.shadowColor = [UIColor blackColor].CGColor;
            [switchButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
            [self.view addSubview:switchButton];
        }
        
        /*UIView *bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, self.view.frame.size.height - BOTTOM_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - BOTTOM_BAR_HEIGHT)];
        bottomBar.backgroundColor = [UIColor blackColor];
        [self.view addSubview:bottomBar];*/
        
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
        galleryButton.layer.shadowOffset = CGSizeMake(0, 0);
        galleryButton.layer.shadowOpacity = 0.7;
        galleryButton.layer.shadowRadius = 4;
        galleryButton.layer.shadowColor = [UIColor blackColor].CGColor;
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
            [takePictureButton setImage:[UIImage imageNamed:@"trianglam_camera.png"] forState:UIControlStateNormal];
            [takePictureButton addTarget:self action:@selector(takePicture:) forControlEvents:UIControlEventTouchUpInside];
            takePictureButton.layer.shadowOffset = CGSizeMake(0, 0);
            takePictureButton.layer.shadowOpacity = 0.9;
            takePictureButton.layer.shadowRadius = 8;
            takePictureButton.layer.shadowColor = [UIColor blackColor].CGColor;
            [self.view addSubview:takePictureButton];
            [camera showPreviewInView:cameraView];
        }
        
        chooseFromGallery = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - BOTTOM_BAR_HEIGHT + BOTTOM_BAR_PADDING, self.view.frame.size.height - BOTTOM_BAR_HEIGHT + BOTTOM_BAR_PADDING, BOTTOM_BAR_HEIGHT - 2.0 * BOTTOM_BAR_PADDING, BOTTOM_BAR_HEIGHT - 2.0 * BOTTOM_BAR_PADDING)];
        //[chooseFromGallery setTitle:@"Gal" forState:UIControlStateNormal];
        [chooseFromGallery setImage:[UIImage imageNamed:@"trianglam_gallery.png"] forState:UIControlStateNormal];
        chooseFromGallery.layer.shadowOffset = CGSizeMake(0, 0);
        chooseFromGallery.layer.shadowOpacity = 0.9;
        chooseFromGallery.layer.shadowRadius = 6;
        chooseFromGallery.layer.shadowColor = [UIColor blackColor].CGColor;
        [chooseFromGallery addTarget:self action:@selector(chooseFromGallery:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:chooseFromGallery];
        
        // picture preview
        pictureView = [[UIImageView alloc] initWithFrame:cameraFrame];
        pictureView.center = self.view.center;
        pictureView.alpha = 0.0;
        pictureView.contentMode = UIViewContentModeScaleAspectFill;
        pictureView.layer.masksToBounds = YES;
        [self.view addSubview:pictureView];
        
        processedView = [[UIImageView alloc] initWithFrame:cameraFrame];
        processedView.center = self.view.center;
        processedView.alpha = 0.0;
        processedView.contentMode = UIViewContentModeScaleAspectFill;
        processedView.layer.masksToBounds = YES;
        [self.view addSubview:processedView];
        
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
        okButton.layer.shadowOffset = CGSizeMake(0, 0);
        okButton.layer.shadowOpacity = 0.9;
        okButton.layer.shadowRadius = 6;
        okButton.layer.shadowColor = [UIColor blackColor].CGColor;
        okButton.alpha = 0.0;
        [okButton addTarget:self action:@selector(acceptImage:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:okButton];
        
        CGRect notOkButtonFrame = CGRectMake(self.view.frame.size.width / 2.0 - BOTTOM_BAR_HEIGHT + BUTTON_FLASH_PADDING_SIDE, self.view.frame.size.height - BOTTOM_BAR_HEIGHT + BOTTOM_BAR_PADDING, BOTTOM_BAR_HEIGHT - 2.0 * BOTTOM_BAR_PADDING, BOTTOM_BAR_HEIGHT - 2.0 * BOTTOM_BAR_PADDING);
        notOkButton = [[UIButton alloc] initWithFrame:notOkButtonFrame];
        [notOkButton setImage:[UIImage imageNamed:@"trianglam_close.png"] forState:UIControlStateNormal];
        notOkButton.layer.shadowOffset = CGSizeMake(0, 0);
        notOkButton.layer.shadowOpacity = 0.9;
        notOkButton.layer.shadowRadius = 6;
        notOkButton.layer.shadowColor = [UIColor blackColor].CGColor;
        notOkButton.alpha = 0.0;
        [notOkButton addTarget:self action:@selector(releaseImage:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:notOkButton];
        
        // flash dropdown
        flashDropDown = [[DropDown alloc] initWithFrame:CGRectMake(self.view.frame.size.width - BUTTON_FLASH_PADDING_SIDE * 2.0 - BUTTON_FLASH_SIZE * 2.0, self.view.frame.size.height / 2.0 - self.view.frame.size.width / 2.0 - BUTTON_FLASH_PADDING_TOP - BUTTON_FLASH_SIZE, BUTTON_FLASH_SIZE, BUTTON_FLASH_SIZE)];
        [self.view addSubview:flashDropDown];
        
        UIButton *flashAutoButton = [[UIButton alloc] init];
        [flashAutoButton setImage:[UIImage imageNamed:@"trianglam_flash_auto.png"] forState:UIControlStateNormal];
        
        UIButton *flashOnButton = [[UIButton alloc] init];
        [flashOnButton setImage:[UIImage imageNamed:@"trianglam_flash_on.png"] forState:UIControlStateNormal];
        
        UIButton *flashOffButton = [[UIButton alloc] init];
        [flashOffButton setImage:[UIImage imageNamed:@"trianglam_flash_off.png"] forState:UIControlStateNormal];
        
        flashDropDown.buttons = @[flashAutoButton, flashOnButton, flashOffButton];
        [flashDropDown addTarget:self action:@selector(setFlash:) forControlEvents:UIControlEventTouchUpInside];
        flashDropDown.layer.shadowOffset = CGSizeMake(0, 0);
        flashDropDown.layer.shadowOpacity = 0.95;
        flashDropDown.layer.shadowRadius = 8;
        flashDropDown.layer.shadowColor = [UIColor blackColor].CGColor;
        
        // settings
        sizeDropDown = [[DropDown alloc] initWithFrame:CGRectMake(BUTTON_FLASH_PADDING_SIDE * 2.0 + BUTTON_FLASH_SIZE, self.view.frame.size.height / 2.0 - self.view.frame.size.width / 2.0 - BUTTON_FLASH_PADDING_TOP - BUTTON_FLASH_SIZE, BUTTON_FLASH_SIZE, BUTTON_FLASH_SIZE)];
        [self.view addSubview:sizeDropDown];
        
        UIButton *smallSizeButton = [[UIButton alloc] init];
        [smallSizeButton setTitle:@"S" forState:UIControlStateNormal];
        smallSizeButton.titleLabel.font = [UIFont boldSystemFontOfSize:32.0];
        
        UIButton *middleSizeButton = [[UIButton alloc] init];
        [middleSizeButton setTitle:@"M" forState:UIControlStateNormal];
        middleSizeButton.titleLabel.font = [UIFont boldSystemFontOfSize:32.0];
        
        UIButton *largeSizeButton = [[UIButton alloc] init];
        [largeSizeButton setTitle:@"L" forState:UIControlStateNormal];
        largeSizeButton.titleLabel.font = [UIFont boldSystemFontOfSize:32.0];
        
        sizeDropDown.buttons = @[smallSizeButton, middleSizeButton, largeSizeButton];
        sizeDropDown.selectedButtonIndex = 1;
        [sizeDropDown addTarget:self action:@selector(setSize:) forControlEvents:UIControlEventTouchUpInside];
        sizeDropDown.layer.shadowOffset = CGSizeMake(0, 0);
        sizeDropDown.layer.shadowOpacity = 0.95;
        sizeDropDown.layer.shadowRadius = 8;
        sizeDropDown.layer.shadowColor = [UIColor blackColor].CGColor;
        
        // shape dropdown
        shapeDropDown = [[DropDown alloc] initWithFrame:CGRectMake(BUTTON_FLASH_PADDING_SIDE, self.view.frame.size.height / 2.0 - self.view.frame.size.width / 2.0 - BUTTON_FLASH_PADDING_TOP - BUTTON_FLASH_SIZE, BUTTON_FLASH_SIZE, BUTTON_FLASH_SIZE)];
        [self.view addSubview:shapeDropDown];
        
        UIButton *triangleButton = [[UIButton alloc] init];
        [triangleButton setImage:[UIImage imageNamed:@"trianglam_triangle_icon.png"] forState:UIControlStateNormal];
        
        UIButton *squareButton = [[UIButton alloc] init];
        [squareButton setImage:[UIImage imageNamed:@"trianglam_square_icon.png"] forState:UIControlStateNormal];
        
        UIButton *hexagonButton = [[UIButton alloc] init];
        [hexagonButton setTitle:@"H" forState:UIControlStateNormal];
        hexagonButton.titleLabel.font = [UIFont boldSystemFontOfSize:32.0];
        
        shapeDropDown.buttons = @[triangleButton, squareButton, hexagonButton];
        [shapeDropDown addTarget:self action:@selector(setShape:) forControlEvents:UIControlEventTouchUpInside];
        shapeDropDown.layer.shadowOffset = CGSizeMake(0, 0);
        shapeDropDown.layer.shadowOpacity = 0.95;
        shapeDropDown.layer.shadowRadius = 8;
        shapeDropDown.layer.shadowColor = [UIColor blackColor].CGColor;
        
        [self reloadUserInterface];
    }
    return self;
}

/*- (void)viewDidAppear:(BOOL)animated
{
    if (camera.cameraCount == 0) {
        [self chooseFromGallery:nil];
    }
    [super viewWillAppear:animated];
}*/

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
    [UIView animateWithDuration:0.4 animations:^(void){
        processedView.frame = galleryButton.frame;
    } completion:^(BOOL finished){
        galleryButton.alpha = 1.0;
        [galleryButton setImage:thumbImage forState:UIControlStateNormal];
        processedView.frame = cameraView.frame;
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
