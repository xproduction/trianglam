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
        self.delegate = delegate;
        self.path = path;
        self.index = index;
        self.imageView = imageView;
    }
    return self;
}

- (void)main {
    
    CGDataProviderRef imageDataProvider = CGDataProviderCreateWithFilename([_path fileSystemRepresentation]);
    
    CGImageRef image = CGImageCreateWithJPEGDataProvider(imageDataProvider, NULL, NO, kCGRenderingIntentDefault);
    
    if (self.isCancelled)
    {
        CGImageRelease(image);
        CGDataProviderRelease(imageDataProvider);
        return;
    }
    
    // Create a bitmap context from the image's specifications
    // (Note: We need to specify kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little
    // because PNGs are optimized by Xcode this way.)
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, CGImageGetWidth(image), CGImageGetHeight(image), CGImageGetBitsPerComponent(image), CGImageGetWidth(image) * 4, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    CGContextSetInterpolationQuality(bitmapContext, kCGInterpolationNone);
    
    if (self.isCancelled)
    {
        CGImageRelease(image);
        CGDataProviderRelease(imageDataProvider);
        CGContextRelease(bitmapContext);
        CGColorSpaceRelease(colorSpace);
        return;
    }
    
    // Draw the image into the bitmap context and retrieve the
    // decompressed image
    CGContextDrawImage(bitmapContext, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    
    CGImageRef decompressedImage = CGBitmapContextCreateImage(bitmapContext);
    
    if (self.isCancelled)
    {
        CGImageRelease(decompressedImage);
        CGContextRelease(bitmapContext);
        CGColorSpaceRelease(colorSpace);
        CGImageRelease(image);
        CGDataProviderRelease(imageDataProvider);
        return;
    }
    
    // Create a UIImage
    self.renderedImage = [[UIImage alloc] initWithCGImage:decompressedImage];
    
    if (self.isCancelled)
    {
        CGImageRelease(decompressedImage);
        CGContextRelease(bitmapContext);
        CGColorSpaceRelease(colorSpace);
        CGImageRelease(image);
        CGDataProviderRelease(imageDataProvider);
        return;
    }
    
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

-(BOOL)isEqual:(id)other
{
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return self.index == ((ImageRenderOperation*)other).index;
}

-(NSUInteger)hash
{
    NSUInteger prime = 31;
    NSUInteger result = 1;
    
    result = prime * result + self.index;
    
    return result;
}

@end
