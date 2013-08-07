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
#import "RGMPageControl.h"

@interface ImageViewController ()

@end

static NSString *reuseIdentifier = @"RGMPageReuseIdentifier";

@implementation ImageViewController

- (id)initWithImageAtIndex:(NSUInteger)index
{
    self = [super init];
    if (self) {
        currentIndex = index;
        images = [Gallery getImageArray];
        
        scrollView = [[RGMPagingScrollView alloc] initWithFrame:self.view.frame];
        scrollView.scrollDirection = RGMScrollDirectionHorizontal;
        scrollView.delegate = self;
        scrollView.datasource = self;
        scrollView.currentPage = index;
        
        [self.view addSubview:scrollView];
        
        [scrollView registerClass:[UIImageView class] forCellReuseIdentifier:reuseIdentifier];
        
        fullScreenImages = [[NSMutableDictionary alloc] init];
        
        queue = [[NSOperationQueue alloc] init];
        queue.name = @"GalleryQueue";
        
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showOrHideControls:)];
        [scrollView addGestureRecognizer:singleTap];
         
        [self renewInterface];
    }
    return self;
}

-(void)didReceiveMemoryWarning
{
    [fullScreenImages removeAllObjects];
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

- (IBAction)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (IBAction)remove:(id)sender
{
    UIImageView *backupView;
    
    UIImageView* imageView = (UIImageView*)[scrollView dequeueReusablePageWithIdentifer:reuseIdentifier forIndex:currentIndex];
    
    backupView = [[UIImageView alloc] init];
    backupView.backgroundColor = [UIColor blackColor];
    backupView.frame = currentImageView.frame;
    backupView.image = currentImageView.image;
    backupView.contentMode = UIViewContentModeScaleAspectFit;
    [scrollView insertSubview:backupView aboveSubview:currentImageView];
    
    [UIView animateWithDuration:0.3 animations:^(void){
        backupView.frame = CGRectMake(currentImageView.frame.size.width / 2.0 - 1.0, currentImageView.frame.size.height / 2.0 - 1.0, 2.0, 2.0);
    } completion:^(BOOL finished){
        [backupView removeFromSuperview];
    }];
    
    //[Gallery removeImageAtIndex:currentIndex];
    //images = [Gallery getImageArray];
    
    [scrollView reloadData];
    
    scrollView.currentPage = currentIndex--;
    
    return;
    
    AppDelegate *appDelegate = ((AppDelegate*)[UIApplication sharedApplication].delegate);
    
    if (images.count > 0)
    {
        if (images.count == currentIndex)
        {
            currentIndex--;
            
            UIImage* thnFirst = [UIImage imageWithContentsOfFile:[[images objectAtIndex:currentIndex] objectForKey:@"thumb"]];
            UIButton* galleryButton = ((CameraViewController*)appDelegate.cameraController).galleryButton;
            [galleryButton setImage:thnFirst forState:UIControlStateNormal];
        }
    } else {
        ((CameraViewController*)appDelegate.cameraController).galleryButton.alpha = 0.0;
        
        [self dismiss:nil];
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

#pragma mark - RGMPagingScrollViewDatasource

- (NSInteger)pagingScrollViewNumberOfPages:(RGMPagingScrollView *)pagingScrollView
{
    return images.count;
}

- (UIView *)pagingScrollView:(RGMPagingScrollView *)pagingScrollView viewForIndex:(NSInteger)idx
{
    
    if ([fullScreenImages objectForKey:[NSNumber numberWithInt:idx-2]])
    {
        [fullScreenImages removeObjectForKey:[NSNumber numberWithInt:idx-2]];
    }
    if ([fullScreenImages objectForKey:[NSNumber numberWithInt:idx+2]])
    {
        [fullScreenImages removeObjectForKey:[NSNumber numberWithInt:idx+2]];
    }
    
    if (queue.operationCount > 3)
        [queue cancelAllOperations];
    
    UIImageView* imageView = (UIImageView*)[pagingScrollView dequeueReusablePageWithIdentifer:reuseIdentifier forIndex:idx];
    currentImageView = imageView;
    currentIndex = idx;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    if ([fullScreenImages objectForKey:[NSNumber numberWithInt:idx]])
    {
        imageView.image = [fullScreenImages objectForKey:[NSNumber numberWithInt:idx]];
    } else {
        imageView.image = [Gallery getThumbAtIndex:idx];
        
        ImageRenderOperation* operation = [[ImageRenderOperation alloc] initWithImage:[[images objectAtIndex:idx] objectForKey:@"image"] delegate:self index:idx andImageView:imageView];
        [queue addOperation:operation];
    }
    
    return imageView;
}

#pragma mark ImageRenderDelegate

-(void)renderDidFinish:(ImageRenderOperation *)op
{
    // set image to the current imageView
    if (scrollView.currentPage == op.index)
        op.imageView.image = op.renderedImage;
    
    if (fullScreenImages.count > 3)
        [fullScreenImages removeAllObjects];
    
    [fullScreenImages setObject:op.renderedImage forKey:[NSNumber numberWithInt:op.index]];
}


@end
