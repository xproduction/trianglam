//
//  ImageRenderOperation.h
//  Trianglam
//
//  Created by Petr Zvoníček on 07.08.13.
//  Copyright (c) 2013 X Production s.r.o. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ImageRenderDelegate;

@interface ImageRenderOperation : NSOperation

-(id)initWithImage:(NSString*)path delegate:(id<ImageRenderDelegate>)delegate index:(NSInteger)index andImageView:(UIImageView*)imageView;

@property (nonatomic, assign) id <ImageRenderDelegate> delegate;
@property (nonatomic, strong) NSString* path;
@property (nonatomic, strong) UIImage* renderedImage;
@property (nonatomic, strong) UIImageView* imageView;;
@property (nonatomic) NSInteger index;

@end


@protocol ImageRenderDelegate <NSObject>

- (void)renderDidFinish:(ImageRenderOperation*)operation;
@end