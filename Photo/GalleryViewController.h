//
//  GalleryViewController.h
//  Photo
//
//  Created by Matěj Kašpar Jirásek on 28.11.12.
//  Copyright (c) 2012 X Production s.r.o. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GalleryViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>
{
    //UIImageView *previewView;
    UICollectionView *collectionView;
    UIDocumentInteractionController *interactionController;
}

@end
