//
//  Gallery.h
//  Photo
//
//  Created by Matěj Kašpar Jirásek on 28.11.12.
//  Copyright (c) 2012 X Production s.r.o. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Gallery : NSObject

+ (NSArray *)getImageArray;
- (BOOL)addImage:(UIImage *)image thumb:(UIImage *)thumb vector:(NSString *)vector;
+ (UIImage *)getImageAtIndex:(NSUInteger)index;
+ (UIImage *)getThumbAtIndex:(NSUInteger)index;
+ (BOOL)removeImageAtIndex:(NSUInteger)index;
+ (void)checkImagesIntegrity;

@end
