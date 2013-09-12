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
#import "UIViewController+TopAndBottomBlur.h"

@interface ImageViewController (TopAndBottomBlur)

@end

static NSString *reuseIdentifier = @"RGMPageReuseIdentifier";

@implementation ImageViewController

- (id)initWithImageAtIndex:(NSUInteger)index
{
    self = [super init];
    if (self) {
        // ui sweetness
        [self addTopAndBottomBlur];
        
        currentIndex = index;
        images = [Gallery getImageArray];
        
        scrollView = [[RGMPagingScrollView alloc] initWithFrame:self.view.frame];
        scrollView.scrollDirection = RGMScrollDirectionHorizontal;
        scrollView.delegate = self;
        scrollView.datasource = self;
        scrollView.currentPage = images.count - index - 1;
        
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

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)renewInterface
{
    bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, (self.view.frame.size.height / 2.0 + self.view.frame.size.width / 2.0) + (self.view.frame.size.height - (self.view.frame.size.height / 2.0 + self.view.frame.size.width / 2.0)) / 2.0 - BOTTOM_BAR_HEIGHT / 2.0, self.view.frame.size.width, BOTTOM_BAR_HEIGHT)];
    
        UIButton *instagramButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, BOTTOM_BAR_HEIGHT, BOTTOM_BAR_HEIGHT)];
        [instagramButton setImage:[UIImage imageNamed:@"Share.png"] forState:UIControlStateNormal];
        [instagramButton setImage:[UIImage imageNamed:@"ShareTouched.png"] forState:UIControlStateHighlighted];
        [instagramButton addTarget:self action:@selector(shareToInstagram:) forControlEvents:UIControlEventTouchUpInside];
        [bottomBar addSubview:instagramButton];
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(BOTTOM_BAR_HEIGHT, 0.0, BOTTOM_BAR_HEIGHT, BOTTOM_BAR_HEIGHT)];
        [button setImage:[UIImage imageNamed:@"Facebook.png"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"FacebookTouched.png"] forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(shareToFacebook:) forControlEvents:UIControlEventTouchUpInside];
        [bottomBar addSubview:button];
    }
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(BOTTOM_BAR_HEIGHT * 2.0, 0.0, BOTTOM_BAR_HEIGHT, BOTTOM_BAR_HEIGHT)];
        [button setImage:[UIImage imageNamed:@"Twitter.png"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"TwitterTouched.png"] forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(shareToTwitter:) forControlEvents:UIControlEventTouchUpInside];
        [bottomBar addSubview:button];
    }
    
    if ([MFMailComposeViewController canSendMail]) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(BOTTOM_BAR_HEIGHT * 3.0, 0.0, BOTTOM_BAR_HEIGHT, BOTTOM_BAR_HEIGHT)];
        [button setImage:[UIImage imageNamed:@"Mail.png"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"MailTouched.png"] forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(mail:) forControlEvents:UIControlEventTouchUpInside];
        [bottomBar addSubview:button];
    }
    
    [self.view addSubview:bottomBar];
    
    topBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height / 2.0 - self.view.frame.size.width / 2.0)];
    //topBar.backgroundColor = [UIColor lightGrayColor];
    
    UIButton *dismissButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, topBar.frame.size.height / 2.0 - 40.0, 80.0, 80.0)];
    [dismissButton setImage:[UIImage imageNamed:@"Close.png"] forState:UIControlStateNormal];
    [dismissButton setImage:[UIImage imageNamed:@"CloseTouched.png"] forState:UIControlStateHighlighted];
    [dismissButton addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:dismissButton];
    
    UIButton *removeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 80.0, topBar.frame.size.height / 2.0 - 40.0, 80.0, 80.0)];
    [removeButton setImage:[UIImage imageNamed:@"Trash.png"] forState:UIControlStateNormal];
    [removeButton setImage:[UIImage imageNamed:@"TrashTouched.png"] forState:UIControlStateHighlighted];
    [removeButton addTarget:self action:@selector(remove:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:removeButton];
    
    [self.view addSubview:topBar];
    
    topBar.alpha = 0.0;
    bottomBar.alpha = 0.0;
    [self setBlurAlpha:0];
}

- (IBAction)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (IBAction)remove:(id)sender
{
    currentImageView.hidden = YES;
    
    UIImageView *backupView = [[UIImageView alloc] init];
    backupView.backgroundColor = [UIColor blackColor];
    backupView.frame = CGRectMake(currentImageView.frame.origin.x, self.view.frame.size.height / 2.0 - self.view.frame.size.width / 2.0, self.view.frame.size.width, self.view.frame.size.width);
    backupView.image = currentImageView.image;
    backupView.contentMode = UIViewContentModeScaleAspectFit;
    [scrollView insertSubview:backupView aboveSubview:currentImageView];
    
    [UIView animateWithDuration:0.3 animations:^(void){
        backupView.frame = CGRectMake(scrollView.contentOffset.x + self.view.frame.size.width / 2.0, scrollView.contentOffset.y + self.view.frame.size.height / 2.0, 2.0, 2.0);
    } completion:^(BOOL finished){
        currentImageView.hidden = NO;
        [backupView removeFromSuperview];
        [scrollView reloadData];
        scrollView.currentPage = images.count - currentIndex - 1;
    }];
    
    [Gallery removeImageAtIndex:currentIndex];
    [fullScreenImages removeAllObjects];
    images = [Gallery getImageArray];
    
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
            [self setBlurAlpha:1.0];
        }];
    }
    else
    {
        [UIView animateWithDuration:0.4 animations:^(void){
            bottomBar.alpha = 0.0;
            topBar.alpha = 0.0;
            [self setBlurAlpha:0.0];
        }];
    }
}

#pragma mark - Sharing
           
- (IBAction)shareToInstagram:(id)sender
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"instagram://app"]])
    {
        interactionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:filename]];
        interactionController.UTI = @"com.instagram.exclusivegram";
        interactionController.annotation = @{@"InstagramCaption" : NSLocalizedString(@"Taken with #trianglam", nil)};
        [interactionController presentOpenInMenuFromRect:self.view.frame inView:self.view animated:YES];
    }
}

- (IBAction)openIn:(id)sender
{
    interactionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:filename]];
    [interactionController presentOpenInMenuFromRect:self.view.frame inView:self.view animated:YES];
}

- (IBAction)shareTo:(id)sender
{
    NSString *shareString = @"Taken with #trianglam";
    UIImage *shareImage = [UIImage imageWithContentsOfFile:filename];
    
    NSArray *activityItems = [NSArray arrayWithObjects:shareString, shareImage, nil];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentViewController:activityViewController animated:YES completion:nil];
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

- (UIView *)pagingScrollView:(RGMPagingScrollView *)pagingScrollView viewForIndex:(NSInteger)backwardIndex
{
    currentIndex = images.count - backwardIndex - 1;
    filename = [[images objectAtIndex:currentIndex] objectForKey:@"image"] ;
    
    if ([fullScreenImages objectForKey:[NSNumber numberWithInt:currentIndex-2]])
    {
        [fullScreenImages removeObjectForKey:[NSNumber numberWithInt:currentIndex-2]];
    }
    if ([fullScreenImages objectForKey:[NSNumber numberWithInt:currentIndex+2]])
    {
        [fullScreenImages removeObjectForKey:[NSNumber numberWithInt:currentIndex+2]];
    }
    
    if (queue.operationCount > 2)
        [queue cancelAllOperations];
    
    UIImageView* imageView = (UIImageView*)[pagingScrollView dequeueReusablePageWithIdentifer:reuseIdentifier forIndex:currentIndex];
    currentImageView = imageView;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    if ([fullScreenImages objectForKey:[NSNumber numberWithInt:currentIndex]])
    {
        imageView.image = [fullScreenImages objectForKey:[NSNumber numberWithInt:currentIndex]];
    } else {
        imageView.image = [Gallery getThumbAtIndex:currentIndex];
        
        ImageRenderOperation* operation = [[ImageRenderOperation alloc] initWithImage:[[images objectAtIndex:currentIndex] objectForKey:@"image"] delegate:self index:currentIndex andImageView:imageView];
        [operation setQueuePriority:NSOperationQueuePriorityVeryHigh];
        
        if (![[queue operations] containsObject:operation])
        {
            [queue addOperation:operation];
        } else {
            NSLog(@"already rendering");
        }
    }
    
    return imageView;
}

#pragma mark ImageRenderDelegate

-(void)renderDidFinish:(ImageRenderOperation *)op
{
    // set image to the current imageView
    if (op.imageView.tag == images.count - op.index - 1)
        op.imageView.image = op.renderedImage;
    
    [fullScreenImages setObject:op.renderedImage forKey:[NSNumber numberWithInt:op.index]];
}


@end
