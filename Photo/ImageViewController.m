//
//  ImageViewController.m
//  Photo
//
//  Created by Matěj Kašpar Jirásek on 04.12.12.
//  Copyright (c) 2012 X Production s.r.o. All rights reserved.
//

#import <Social/Social.h>
#import <MessageUI/MessageUI.h>

#import "ImageViewController.h"
#import "Gallery.h"
#import "AppDelegate.h"
#import "CameraViewController.h"

@interface ImageViewController ()

@end

@implementation ImageViewController

- (id)initWithImageAtIndex:(NSUInteger)index
{
    self = [super init];
    if (self) {
        currentIndex = index;
        images = [Gallery getImageArray];
        
        scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
        scrollView.pagingEnabled = YES;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.delegate = self;
        scrollView.contentSize = CGSizeMake(self.view.frame.size.width * images.count + 1, self.view.frame.size.height);
        [self.view addSubview:scrollView];
        
        currentImageView = [[UIImageView alloc] init];
        currentImageView.backgroundColor = [UIColor blackColor];
        currentImageView.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
        currentImageView.contentMode = UIViewContentModeScaleAspectFit;
        [scrollView addSubview:currentImageView];
        
        previousImageView = [[UIImageView alloc] init];
        previousImageView.backgroundColor = [UIColor blackColor];
        previousImageView.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
        previousImageView.contentMode = UIViewContentModeScaleAspectFit;
        [scrollView addSubview:previousImageView];
        
        nextImageView = [[UIImageView alloc] init];
        nextImageView.backgroundColor = [UIColor blackColor];
        nextImageView.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
        nextImageView.contentMode = UIViewContentModeScaleAspectFit;
        [scrollView addSubview:nextImageView];
        
        [self loadImages];
        [self moveImageViews];
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, scrollView.contentSize.width, scrollView.contentSize.height)];
        [button addTarget:self action:@selector(showOrHideControls:) forControlEvents:UIControlEventTouchUpInside];
        [scrollView addSubview:button];
        
        [self renewInterface];
    }
    return self;
}


- (void)renewInterface
{
    bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, self.view.frame.size.height - BOTTOM_BAR_HEIGHT - STATUS_BAR_HEIGHT, self.view.frame.size.width, BOTTOM_BAR_HEIGHT)];
    
    if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"instagram://app"]])
    {
        UIButton *instagramButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, BOTTOM_BAR_HEIGHT, BOTTOM_BAR_HEIGHT)];
        [instagramButton setImage:[UIImage imageNamed:@"trianglam_instagram.png"] forState:UIControlStateNormal];
        [instagramButton addTarget:self action:@selector(shareToInstagram:) forControlEvents:UIControlEventTouchUpInside];
        [bottomBar addSubview:instagramButton];
    }
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(BOTTOM_BAR_HEIGHT, 0.0, BOTTOM_BAR_HEIGHT, BOTTOM_BAR_HEIGHT)];
        [button setImage:[UIImage imageNamed:@"trianglam_fb.png"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(shareToFacebook:) forControlEvents:UIControlEventTouchUpInside];
        [bottomBar addSubview:button];
    }
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(BOTTOM_BAR_HEIGHT * 2.0, 0.0, BOTTOM_BAR_HEIGHT, BOTTOM_BAR_HEIGHT)];
        [button setImage:[UIImage imageNamed:@"trianglam_twitter.png"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(shareToTwitter:) forControlEvents:UIControlEventTouchUpInside];
        [bottomBar addSubview:button];
    }
    
    if ([MFMailComposeViewController canSendMail]) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(BOTTOM_BAR_HEIGHT * 3.0, 0.0, BOTTOM_BAR_HEIGHT, BOTTOM_BAR_HEIGHT)];
        [button setImage:[UIImage imageNamed:@"trianglam_mail.png"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(mail:) forControlEvents:UIControlEventTouchUpInside];
        [bottomBar addSubview:button];
    }
    
    [self.view addSubview:bottomBar];
    
    topBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 80.0)];
    //topBar.backgroundColor = [UIColor lightGrayColor];
    
    UIButton *dismissButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 80.0, 80.0)];
    [dismissButton setImage:[UIImage imageNamed:@"trianglam_close.png"] forState:UIControlStateNormal];
    [dismissButton addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:dismissButton];
    
    UIButton *removeButton = [[UIButton alloc] initWithFrame:CGRectMake(160.0, 0.0, 80.0, 80.0)];
    [removeButton setImage:[UIImage imageNamed:@"trianglam_trash.png"] forState:UIControlStateNormal];
    [removeButton addTarget:self action:@selector(remove:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:removeButton];
    
    [self.view addSubview:topBar];
    
    topBar.alpha = 0.0;
    bottomBar.alpha = 0.0;
}

- (void)loadImages
{
    filename = [[images objectAtIndex:currentIndex] objectForKey:@"image"];
    [scrollView scrollRectToVisible:CGRectMake((images.count - currentIndex - 1) * self.view.frame.size.width, 0.0, self.view.frame.size.width, self.view.frame.size.height) animated:NO];
    if (currentIndex > 0)
    {
        nextImageView.image = [UIImage imageWithContentsOfFile:[[images objectAtIndex:currentIndex - 1] objectForKey:@"image"]];
    }
    currentImageView.image = [UIImage imageWithContentsOfFile:[[images objectAtIndex:currentIndex] objectForKey:@"image"]];
    if (currentIndex < images.count - 1)
    {
        previousImageView.image = [UIImage imageWithContentsOfFile:[[images objectAtIndex:currentIndex + 1] objectForKey:@"image"]];
    }
}

- (void)nextImage
{
    filename = [[images objectAtIndex:currentIndex] objectForKey:@"image"];
    previousImageView.image = currentImageView.image;
    currentImageView.image = nextImageView.image;
    if (currentIndex > 0)
    {
        nextImageView.image = [UIImage imageWithContentsOfFile:[[images objectAtIndex:currentIndex - 1] objectForKey:@"image"]];
    }
    else
    {
        nextImageView.image = nil;
    }
    [self moveImageViews];
}

- (void)previousImage
{
    filename = [[images objectAtIndex:currentIndex] objectForKey:@"image"];
    nextImageView.image = currentImageView.image;
    currentImageView.image = previousImageView.image;
    if (currentIndex < images.count - 1)
    {
        previousImageView.image = [UIImage imageWithContentsOfFile:[[images objectAtIndex:currentIndex + 1] objectForKey:@"image"]];
    }
    else
    {
        previousImageView.image = nil;
    }
    [self moveImageViews];
}

- (void)moveImageViews
{
    previousImageView.frame = CGRectMake((images.count - currentIndex - 2) * self.view.frame.size.width, 0.0, self.view.frame.size.width, self.view.frame.size.height);
    currentImageView.frame = CGRectMake((images.count - currentIndex - 1) * self.view.frame.size.width, 0.0, self.view.frame.size.width, self.view.frame.size.height);
    nextImageView.frame = CGRectMake((images.count - currentIndex) * self.view.frame.size.width, 0.0, self.view.frame.size.width, self.view.frame.size.height);
}

- (IBAction)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)remove:(id)sender
{
    UIImageView *backupView = currentImageView;
    
    currentImageView = [[UIImageView alloc] init];
    currentImageView.backgroundColor = [UIColor blackColor];
    currentImageView.frame = backupView.frame;
    currentImageView.contentMode = UIViewContentModeScaleAspectFit;
    [scrollView insertSubview:currentImageView belowSubview:backupView];
    
    [UIView animateWithDuration:0.3 animations:^(void){
        backupView.frame = CGRectMake((images.count - currentIndex - 1) * self.view.frame.size.width + self.view.center.x - 1.0, self.view.center.y - 1.0, 2.0, 2.0);
    } completion:^(BOOL finished){
        [backupView removeFromSuperview];
    }];
    
    [Gallery removeImageAtIndex:currentIndex];
    images = [Gallery getImageArray];
        
    if (images.count > 0)
    {
        if (images.count == currentIndex)
            currentIndex--;
        
        [self loadImages];
        [self moveImageViews];
    } else {
        AppDelegate *appDelegate = ((AppDelegate*)[UIApplication sharedApplication].delegate);
        ((CameraViewController*)appDelegate.cameraController).galleryButton.alpha = 0.0;
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)showOrHideControls:(id)sender
{
    if(bottomBar.alpha == 0.0)
    {
        [UIView animateWithDuration:0.4 animations:^(void){
            bottomBar.alpha = 1.0;
            topBar.alpha = 1.0;
        }];
    }
    else
    {
        [UIView animateWithDuration:0.4 animations:^(void){
            bottomBar.alpha = 0.0;
            topBar.alpha = 0.0;
        }];
    }
}

#pragma mark - Sharing
           
- (IBAction)shareToInstagram:(id)sender
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"instagram://app"]])
    {
        instagramController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:filename]];
        instagramController.UTI = @"com.instagram.exclusivegram";
        instagramController.annotation = @{@"InstagramCaption" : NSLocalizedString(@"Taken with #trianglam", nil)};
        [instagramController presentOpenInMenuFromRect:self.view.frame inView:self.view animated:YES];
    }
}

- (IBAction)shareToTwitter:(id)sender
{
    if([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [controller addImage:[UIImage imageWithContentsOfFile:filename]];
        [controller setInitialText:NSLocalizedString(@"Taken with #trianglam", nil)];
        [self presentViewController:controller animated:YES completion:nil];
    }
}

- (IBAction)shareToFacebook:(id)sender
{
    if([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
    {
        SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [controller addImage:[UIImage imageWithContentsOfFile:filename]];
        [controller setInitialText:NSLocalizedString(@"Taken with #trianglam", nil)];
        [self presentViewController:controller animated:YES completion:nil];
    }
}

- (IBAction)mail:(id)sender
{
    if([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
        [controller setSubject:NSLocalizedString(@"My Trianglam photo", nil)];
        [controller addAttachmentData:[NSData dataWithContentsOfFile:filename] mimeType:@"image/jpeg" fileName:@"trianglam.jpg"];
        controller.mailComposeDelegate = self;
        if(IS_IPAD)
        {
            controller.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        [self presentViewController:controller animated:YES completion:nil];
    }
}

#pragma mark - MFMailComposeDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scroll
{
    NSUInteger oldIndex = currentIndex;
    currentIndex = images.count - (NSUInteger)(scroll.contentOffset.x / scroll.frame.size.width) - 1;
    if(oldIndex < currentIndex)
    {
        [self previousImage];
    }
    if(oldIndex > currentIndex)
    {
        [self nextImage];
    }
    if (bottomBar.alpha == 1.0) {
        [UIView animateWithDuration:0.4 animations:^(void){
            bottomBar.alpha = 0.0;
            topBar.alpha = 0.0;
        }];
    }
    
}

@end
