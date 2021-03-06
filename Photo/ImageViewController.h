//
//  ImageViewController.h
//  Photo
//
//  Created by Matěj Kašpar Jirásek on 04.12.12.
//  Copyright (c) 2012 X Production s.r.o. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "RGMPagingScrollView.h"
#import "ImageRenderOperation.h"

@interface ImageViewController : UIViewController <MFMailComposeViewControllerDelegate, RGMPagingScrollViewDatasource, RGMPagingScrollViewDelegate, ImageRenderDelegate, UIDocumentInteractionControllerDelegate>
{
    NSUInteger previousIndex, currentIndex;
    NSArray *images;
    NSMutableDictionary *fullScreenImages;
    UIDocumentInteractionController *interactionController;
    UIActivityViewController *sharingController;
    UIView *bottomBar, *topBar;
    RGMPagingScrollView *scrollView;
    NSString *filename;
    UIImageView *currentImageView, *previousImageView;
    UIImage* nextImage;
    float lastContentOffset;
    NSOperationQueue* queue;
    
}

- (id)initWithImageAtIndex:(NSUInteger)index;

@end
