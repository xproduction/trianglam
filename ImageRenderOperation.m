//
//  ImageRenderOperation.m
//  Trianglam
//
//  Created by Petr Zvoníček on 07.08.13.
//  Copyright (c) 2013 X Production s.r.o. All rights reserved.
//

#import "ImageRenderOperation.h"

@interface ImageRenderOperation()


@end

@implementation ImageRenderOperation

-(id)initWithImage:(NSString*)path delegate:(id<ImageRenderDelegate>)delegate index:(NSInteger)index andImageView:(UIImageView *)imageView;
{
    if (self = [super init]) {
        // 2
        self.delegate = delegate;
        self.path = path;
        self.index = index;
        self.imageView = imageView;
    }
    return self;
}

- (void)main {
    
    //NSString* path = [[images objectAtIndex:idx] objectForKey:@"image"];
    
    CGDataProviderRef imageDataProvider = CGDataProviderCreateWithFilename([_path fileSystemRepresentation]);
    
    CGImageRef image = CGImageCreateWithJPEGDataProvider(imageDataProvider, NULL, NO, kCGRenderingIntentDefault);
    
    if (self.isCancelled)
        return;
    
    // Create a bitmap context from the image's specifications
    // (Note: We need to specify kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little
    // because PNGs are optimized by Xcode this way.)
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, CGImageGetWidth(image), CGImageGetHeight(image), CGImageGetBitsPerComponent(image), CGImageGetWidth(image) * 4, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    
    if (self.isCancelled)
        return;
    
    // Draw the image into the bitmap context and retrieve the
    // decompressed image
    CGContextDrawImage(bitmapContext, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    
    CGImageRef decompressedImage = CGBitmapContextCreateImage(bitmapContext);
    
    if (self.isCancelled)
        return;
    
    // Create a UIImage
    self.renderedImage = [[UIImage alloc] initWithCGImage:decompressedImage];
    
    if (self.isCancelled)
        return;
    
    // Release everything
    CGImageRelease(decompressedImage);
    CGContextRelease(bitmapContext);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(image);
    CGDataProviderRelease(imageDataProvider);
    
    if (self.isCancelled)
        return;
    
    [(NSObject *)self.delegate performSelectorOnMainThread:@selector(renderDidFinish:) withObject:self waitUntilDone:NO];
}
@end
