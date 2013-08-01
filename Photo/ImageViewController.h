//
//  ImageViewController.h
//  Photo
//
//  Created by Matěj Kašpar Jirásek on 04.12.12.
//  Copyright (c) 2012 X Production s.r.o. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface ImageViewController : UIViewController <MFMailComposeViewControllerDelegate, UIScrollViewDelegate>
{
    NSUInteger currentIndex;
    NSArray *images;
    UIDocumentInteractionController *instagramController;
    UIActivityViewController *sharingController;
    UIView *bottomBar, *topBar;
    UIScrollView *scrollView;
    NSString *filename;
    UIImageView *currentImageView, *previousImageView, *nextImageView;
}

- (id)initWithImageAtIndex:(NSUInteger)index;

@end
