//
//  GalleryCollectionCell.h
//  Photo
//
//  Created by Matěj Kašpar Jirásek on 04.12.12.
//  Copyright (c) 2012 X Production s.r.o. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GalleryCollectionCell : UICollectionViewCell
{
    UIImageView *imageView;
}

@property (nonatomic, strong) UIImageView *imageView;

@end
