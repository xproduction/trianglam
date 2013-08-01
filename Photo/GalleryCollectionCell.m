//
//  GalleryCollectionCell.m
//  Photo
//
//  Created by Matěj Kašpar Jirásek on 04.12.12.
//  Copyright (c) 2012 X Production s.r.o. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "GalleryCollectionCell.h"

@implementation GalleryCollectionCell

@synthesize imageView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height)];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        //imageView.layer.masksToBounds = YES;
        [self.contentView addSubview:imageView];
        self.contentView.layer.masksToBounds = YES;
    }
    return self;
}

@end
