//
//  Image.m
//  triangleFilterApp
//
//  Created by Matěj Kašpar Jirásek on 16.10.12.
//  Copyright (c) 2012 Matěj Kašpar Jirásek. All rights reserved.
//

#import "UIImage+Triangles.h"

#define EQUILATERAL_RATIO (sqrt(3.0) / 2.0)
#define DELTA 0.75
#define D30 0.0
#define D60 M_PI / 3.0

@implementation UIImage (Triangles)

static NSUInteger bytesPerPixel = 4;
static NSUInteger bitsPerComponent = 8;

- (void)getRed:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue andAlpha:(CGFloat *)alpha atPostionX:(NSUInteger)x andY:(NSUInteger)y from:(unsigned char *)rawData width:(NSUInteger)pixelWidth height:(NSUInteger)pixelHeight
{
    
    if(x > pixelWidth - 1 || y > pixelHeight - 1)
    {
        *red = 0.0;
        *blue = 0.0;
        *green = 0.0;
        *alpha = 0.0;
        return;
    }
    
    unsigned long byteIndex = (bytesPerPixel * pixelWidth * y) + x * bytesPerPixel;
    
    *red  = (rawData[byteIndex]     * 1.0) / 255.0;
    *green = (rawData[byteIndex + 1] * 1.0) / 255.0;
    *blue  = (rawData[byteIndex + 2] * 1.0) / 255.0;
    *alpha = (rawData[byteIndex + 3] * 1.0) / 255.0;
}

- (void)getAverageRed:(CGFloat *)totalRed green:(CGFloat *)totalGreen blue:(CGFloat *)totalBlue andAlpha:(CGFloat *)totalAlpha inRect:(CGRect)rect from:(unsigned char *)rawData width:(NSUInteger)pixelWidth height:(NSUInteger)pixelHeight
{
    
    *totalRed = 0, *totalBlue = 0, *totalGreen = 0, *totalAlpha = 0;
    CGFloat red, blue, green, alpha;
    for (NSUInteger y = rect.origin.y; y < rect.origin.y + rect.size.height; y++) {
        for (NSUInteger x = rect.origin.x; x < rect.origin.x + rect.size.width; x++) {
            [self getRed:&red green:&green blue:&blue andAlpha:&alpha atPostionX:x andY:y from:rawData width:pixelWidth height:pixelHeight];
            *totalRed += red;
            *totalGreen += green;
            *totalBlue += blue;
            *totalAlpha += alpha;
        }
    }
    *totalRed /= rect.size.width * rect.size.height;
    *totalGreen /= rect.size.width * rect.size.height;
    *totalBlue /= rect.size.width * rect.size.height;
    *totalAlpha /= rect.size.width * rect.size.height;
    if (*totalRed > 1.0) {
        *totalRed = 1.0;
    }
    if (*totalGreen > 1.0) {
        *totalGreen = 1.0;
    }
    if (*totalBlue > 1.0) {
        *totalBlue = 1.0;
    }
    if (*totalAlpha > 1.0) {
        *totalAlpha = 1.0;
    }
}

- (NSDictionary *)triangleImageWithWidth:(float)width ratio:(NSUInteger)ratio
{
    unsigned char *rawData;
    NSUInteger pixelWidth, pixelHeight;
    
    // raw data init
    CGImageRef imageRef = [self CGImage];
    pixelWidth = CGImageGetWidth(imageRef);
    pixelHeight = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    rawData = (unsigned char*) calloc(pixelHeight * pixelWidth * 4, sizeof(unsigned char));
    CGContextRef ctx = CGBitmapContextCreate(rawData, pixelWidth, pixelHeight,
                                                 bitsPerComponent, bytesPerPixel * pixelWidth, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(ctx, CGRectMake(0, 0, pixelWidth, pixelHeight), imageRef);
    CGContextRelease(ctx);
    
    //
    NSUInteger height = width * EQUILATERAL_RATIO;
    width /= 2;
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char * data = (unsigned char*) calloc(pixelHeight * ratio * pixelWidth * ratio * 4, sizeof(unsigned char));
    CGContextRef context = CGBitmapContextCreate(data, pixelWidth * ratio, pixelHeight * ratio,
                                                 8, 4 * pixelWidth * ratio, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    UIGraphicsPushContext(context);
    CGColorSpaceRelease(colorSpace);
    
    CGAffineTransform flipVertical = CGAffineTransformMake(
                                                           1, 0, 0, -1, 0, pixelHeight * ratio
                                                           );
    CGContextConcatCTM(context, flipVertical);
    
    CGFloat *pixels = malloc(sizeof(CGFloat) * 4 * (self.size.width / width) * (self.size.height / height));
    CGFloat red, blue, green, alpha;
    
    for (NSUInteger y = 0; y < self.size.height / height; y++) {
        for (NSUInteger x = 0; x < self.size.width / width; x++) {
            [self getAverageRed:&red green:&green blue:&blue andAlpha:&alpha inRect:CGRectMake(width * x, height * y, width, height) from:rawData width:pixelWidth height:pixelHeight];
            NSUInteger byteIndex = (self.size.width / width * y * 4) + x * 4;
            pixels[byteIndex] = red;
            pixels[byteIndex + 1] = green;
            pixels[byteIndex + 2] = blue;
            pixels[byteIndex + 3] = alpha;
        }
    }
    
    free(rawData);
    
    //NSMutableString *string = [[NSMutableString alloc] init];
    //[string appendString:@"<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\">\n"];
    
    for (NSUInteger y = 0; y < self.size.height / height; y++) {
        for (NSUInteger x = 0; x < self.size.width / width; x++) {
            NSUInteger byteIndex = (self.size.width / width * y * 4) + x * 4;
            [[UIColor colorWithRed:pixels[byteIndex] green:pixels[byteIndex + 1] blue:pixels[byteIndex + 2] alpha:pixels[byteIndex + 3]] set];
            CGContextBeginPath(context);
            if((x % 2 == 0 && y % 2 == 0) || (x % 2 == 1 && y % 2 == 1))
            {
                CGContextMoveToPoint(context, width * ratio * x - 1.0 / 2.0 * width * ratio - DELTA, height * ratio * y);
                CGContextAddLineToPoint(context, width * ratio * x + width * ratio + 1.0 / 2.0 * width * ratio + DELTA, height * ratio * y);
                CGContextAddLineToPoint(context, width * ratio * x + width * ratio / 2.0, height * ratio * y + height * ratio);
                
                /*[string appendFormat:@"<polygon points=\"%.3f,%d %.3f,%d %f,%d\" style=\"fill:rgb(%d,%d,%d);stroke:none;\"/>\n",
                 width * x - 1.0 / 2.0 * width, height * y,
                 width * x + width + 1.0 / 2.0 * width, height * y,
                 width * x + width / 2, height * y + height,
                 (int)(pixels[byteIndex] * 255), (int)(pixels[byteIndex + 1] * 255), (int)(pixels[byteIndex + 2] * 255)
                 ];*/
            }
            else
            {
                CGContextMoveToPoint(context, width * ratio * x - 1.0 / 2.0 * width * ratio - DELTA, height * ratio * y + height * ratio);
                CGContextAddLineToPoint(context, width * x * ratio + width * ratio + 1.0 / 2.0 * width * ratio + DELTA, height * ratio * y + height * ratio);
                CGContextAddLineToPoint(context, width * x * ratio + width * ratio / 2.0, height * ratio * y);
                
                /*[string appendFormat:@"<polygon points=\"%.3f,%d %.3f,%d %f,%d\" style=\"fill:rgb(%d,%d,%d);stroke:none;\"/>\n",
                 width * x - 1.0 / 2.0 * width, height * y + height,
                 width * x + width + 1.0 / 2.0 * width, height * y + height,
                 width * x + width / 2, height * y,
                 (int)(pixels[byteIndex] * 255), (int)(pixels[byteIndex + 1] * 255), (int)(pixels[byteIndex + 2] * 255)
                 ];*/
            }
            CGContextClosePath(context);
            CGContextFillPath(context);
        }
    }
    
    //[string appendString:@"</svg>"];
    
       
    
    UIGraphicsPopContext();
    free(pixels);
    
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    UIImage *image = [UIImage imageWithCGImage:imgRef];
    
    CGContextRelease(context);
    CGImageRelease(imgRef);
    free(data);
    
    return @{@"image" : image, @"vector" : @""}; // string
}

- (NSDictionary *)squareImageWithWidth:(float)width ratio:(NSUInteger)ratio
{
    unsigned char *rawData;
    NSUInteger pixelWidth, pixelHeight;
    
    if (width > 25) {
        width = 40;
    }
    
    // raw data init
    CGImageRef imageRef = [self CGImage];
    pixelWidth = CGImageGetWidth(imageRef);
    pixelHeight = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    rawData = (unsigned char*) calloc(pixelHeight * pixelWidth * 4, sizeof(unsigned char));
    CGContextRef ctx = CGBitmapContextCreate(rawData, pixelWidth, pixelHeight,
                                             bitsPerComponent, bytesPerPixel * pixelWidth, colorSpace,
                                             kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(ctx, CGRectMake(0, 0, pixelWidth, pixelHeight), imageRef);
    CGContextRelease(ctx);
    
    //
    NSUInteger height = width * 2.0;
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char * data = (unsigned char*) calloc(pixelHeight * ratio * pixelWidth * ratio * 4, sizeof(unsigned char));
    CGContextRef context = CGBitmapContextCreate(data, pixelWidth * ratio, pixelHeight * ratio,
                                                 8, 4 * pixelWidth * ratio, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    UIGraphicsPushContext(context);
    CGColorSpaceRelease(colorSpace);
    
    CGAffineTransform flipVertical = CGAffineTransformMake(
                                                           1, 0, 0, -1, 0, pixelHeight * ratio
                                                           );
    CGContextConcatCTM(context, flipVertical);
    
    CGFloat *pixels = malloc(sizeof(CGFloat) * 4 * (self.size.width / width) * (self.size.height / height));
    CGFloat red, blue, green, alpha;
    
    for (NSUInteger y = 0; y < self.size.height / height; y++) {
        for (NSUInteger x = 0; x < self.size.width / width; x++) {
            [self getAverageRed:&red green:&green blue:&blue andAlpha:&alpha inRect:CGRectMake(width * x, height * y, width, height) from:rawData width:pixelWidth height:pixelHeight];
            NSUInteger byteIndex = (self.size.width / width * y * 4) + x * 4;
            pixels[byteIndex] = red;
            pixels[byteIndex + 1] = green;
            pixels[byteIndex + 2] = blue;
            pixels[byteIndex + 3] = alpha;
        }
    }
    
    free(rawData);
    
    //NSMutableString *string = [[NSMutableString alloc] init];
    //[string appendString:@"<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\">\n"];
    
    for (NSUInteger y = 0; y < self.size.height / height; y++) {
        for (NSUInteger x = 0; x < self.size.width / width; x++) {
            NSUInteger byteIndex = (self.size.width / width * y * 4) + x * 4;
            [[UIColor colorWithRed:pixels[byteIndex] green:pixels[byteIndex + 1] blue:pixels[byteIndex + 2] alpha:pixels[byteIndex + 3]] set];
            CGContextFillRect(context, CGRectMake(width * ratio * x - DELTA, height * ratio * y - DELTA, width * ratio, height * ratio));                
            /*[string appendFormat:@"<rect x=\"%f\" y=\"%d\" width=\"%f\" height=\"%d\" style=\"fill:rgb(%d,%d,%d);stroke:none;\"/>\n",
                 width * x, height * y,
                 width, height,
                 (int)(pixels[byteIndex] * 255), (int)(pixels[byteIndex + 1] * 255), (int)(pixels[byteIndex + 2] * 255)
                 ];*/
        }
    }
    
    //[string appendString:@"</svg>"];
    
    
    
    UIGraphicsPopContext();
    free(pixels);
    
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    UIImage *image = [UIImage imageWithCGImage:imgRef];
    
    CGContextRelease(context);
    CGImageRelease(imgRef);
    free(data);
    
    return @{@"image" : image, @"vector" : @""}; //string
}

- (NSDictionary *)hexagonImageWithWidth:(float)width ratio:(NSUInteger)ratio
{
    unsigned char *rawData;
    NSUInteger pixelWidth, pixelHeight;
    
    // magic constants
    if(width == 35)
        width = 40;
    if(width == 20)
        width = 22;
    
    
    // raw data init
    CGImageRef imageRef = [self CGImage];
    pixelWidth = CGImageGetWidth(imageRef);
    pixelHeight = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    rawData = (unsigned char*) calloc(pixelHeight * pixelWidth * 4, sizeof(unsigned char));
    CGContextRef ctx = CGBitmapContextCreate(rawData, pixelWidth, pixelHeight,
                                             bitsPerComponent, bytesPerPixel * pixelWidth, colorSpace,
                                             kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(ctx, CGRectMake(0, 0, pixelWidth, pixelHeight), imageRef);
    CGContextRelease(ctx);
    
    //
    float height = width;
    height /= EQUILATERAL_RATIO;
    float rowHeight = height * 0.72;
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char * data = (unsigned char*) calloc(pixelHeight * ratio * pixelWidth * ratio * 4, sizeof(unsigned char));
    CGContextRef context = CGBitmapContextCreate(data, pixelWidth * ratio, pixelHeight * ratio,
                                                 8, 4 * pixelWidth * ratio, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    UIGraphicsPushContext(context);
    CGColorSpaceRelease(colorSpace);
    
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, pixelHeight * ratio);
    CGContextConcatCTM(context, flipVertical);
    
    CGFloat *pixels = malloc(sizeof(CGFloat) * 4 * ((self.size.width / width) + 1) * (self.size.height / rowHeight));
    CGFloat red, blue, green, alpha;
    
    for (NSUInteger y = 0; y < self.size.height / rowHeight; y++) {
        for (NSUInteger x = 0; x < self.size.width / width + 1; x++) {
            [self getAverageRed:&red green:&green blue:&blue andAlpha:&alpha inRect:CGRectMake(self.size.width / ((self.size.width / width) + 1) * x, rowHeight * y, self.size.width / ((self.size.width / width) + 1), rowHeight) from:rawData width:pixelWidth height:pixelHeight];
            NSUInteger byteIndex = (self.size.width / width * y * 4) + x * 4;
            pixels[byteIndex] = red;
            pixels[byteIndex + 1] = green;
            pixels[byteIndex + 2] = blue;
            pixels[byteIndex + 3] = alpha;
        }
    }
    
    free(rawData);

    float diffY = rowHeight * 1.0;
    for (NSUInteger y = 0; y < self.size.height / rowHeight; y++) {
        for (NSUInteger x = 0; x < self.size.width / width + 1; x++) {
            NSUInteger byteIndex = (self.size.width / width * y * 4) + x * 4;
            if((self.size.width / width + 1) - x <= 1)
                byteIndex = (self.size.width / width * y * 4) + (x - 1) * 4;
            [[UIColor colorWithRed:pixels[byteIndex] green:pixels[byteIndex + 1] blue:pixels[byteIndex + 2] alpha:1.0] set];
            CGContextBeginPath(context);
            float diffX = 0.0;
            if (y % 2) {
                diffX = - width * ratio / 2.0;
            }

            CGContextMoveToPoint(context, diffX + width * ratio * x + width * ratio / 2.0, diffY + rowHeight * ratio * y - height * ratio * 0.25);
            CGContextAddLineToPoint(context, diffX + width * ratio * x + width * ratio, diffY + rowHeight * ratio * y);
            CGContextAddLineToPoint(context, diffX + width * ratio * x + width * ratio, diffY + rowHeight * ratio * y + height * ratio * 0.5);
            CGContextAddLineToPoint(context, diffX + width * ratio * x + width * ratio  / 2.0, diffY + rowHeight * ratio * y + height * ratio * 0.75);
            CGContextAddLineToPoint(context, diffX + width * ratio * x, diffY + rowHeight * ratio * y + height * ratio * 0.5);
            CGContextAddLineToPoint(context, diffX + width * ratio * x, diffY + rowHeight * ratio * y);
            CGContextClosePath(context);
            CGContextFillPath(context);
        }
    }

    UIGraphicsPopContext();
    free(pixels);
    
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    UIImage *image = [UIImage imageWithCGImage:imgRef];
    
    CGContextRelease(context);
    CGImageRelease(imgRef);
    free(data);
    
    return @{@"image" : image, @"vector" : @""}; // string
}

@end
