//
//  Gallery.m
//  Photo
//
//  Created by Matěj Kašpar Jirásek on 28.11.12.
//  Copyright (c) 2012 X Production s.r.o. All rights reserved.
//

#import "Gallery.h"
#import "AppDelegate.h"

#define GALLERY_KEY @"gallery"
#define IMAGE_FORMAT @"TRIANGLE%f.JPG"
#define THUMB_FORMAT @"TRIANGLE%f_THUMB.JPG"

@implementation Gallery

+ (NSArray *)getImageArray
{
    NSArray *array = [[NSUserDefaults standardUserDefaults] objectForKey:GALLERY_KEY];
    if (array == nil) {
        return @[];
    }
    else
    {
        return array;
    }
}

+ (NSMutableArray *)getMutableArray
{
    return [[self getImageArray] mutableCopy];
}

+ (BOOL)saveArray:(NSArray *)array
{
    if (array == nil) {
        return NO;
    }
    [[NSUserDefaults standardUserDefaults] setObject:array forKey:GALLERY_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return YES;
}

/*+ (BOOL)addImage:(UIImage *)image
{
    NSMutableArray *array = [self getMutableArray];
    NSString *path = [self saveImage:image toIndex:array.count];
    if(path == nil)
    {
        return NO;
    }
    [array addObject:path];
    [self saveArray:array];
    return YES;
    
}*/

+ (BOOL)addImage:(UIImage *)image thumb:(UIImage *)thumb vector:(NSString *)vector
{
    if(image == nil || thumb == nil)
    {
        return NO;
    }
    double time = [[NSDate date] timeIntervalSince1970] * 1000.0;
    NSString *imageFilename = [self saveImage:image to:[NSString stringWithFormat:IMAGE_FORMAT, time]];
    [self saveImageToCameraRoll:image];
    NSString *thumbFilename = [self saveImage:thumb to:[NSString stringWithFormat:THUMB_FORMAT, time]];
    //NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:imageFilename, @"image", thumbFilename, @"thumb", nil];
    NSDictionary *dictionary = @{@"image" : imageFilename, @"thumb" : thumbFilename, @"vector" : vector};
    NSMutableArray *array = [self getMutableArray];
    [array addObject:dictionary];
    [self saveArray:array];
    return YES;
}

+ (BOOL)removeImageAtIndex:(NSUInteger)index
{
    NSMutableArray *array = [self getMutableArray];
    if (index < array.count)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:[[array objectAtIndex:index] objectForKey:@"thumb"]] && [fileManager fileExistsAtPath:[[array objectAtIndex:index] objectForKey:@"image"]])
        {
            NSError *error = nil;
            [fileManager removeItemAtPath:[[array objectAtIndex:index] objectForKey:@"thumb"] error:&error];
            if (error != nil)
            {
                NSLog(@"%@", error);
                return NO;
            }
            [fileManager removeItemAtPath:[[array objectAtIndex:index] objectForKey:@"image"] error:&error];
            if (error != nil)
            {
                NSLog(@"%@", error);
                return NO;
            }
            [array removeObjectAtIndex:index];
            [self saveArray:array];
            return YES;
        }
    }
    return NO;
}

+ (UIImage *)getImageAtIndex:(NSUInteger)index
{
    NSArray *array = [self getImageArray];
    if ([array objectAtIndex:index] != nil) {
        return [UIImage imageWithContentsOfFile:[[array objectAtIndex:index] objectForKey:@"image"]];
    }
    return nil;
}

+ (UIImage *)getThumbAtIndex:(NSUInteger)index
{
    NSArray *array = [self getImageArray];
    if ([array objectAtIndex:index] != nil) {
        return [UIImage imageWithContentsOfFile:[[array objectAtIndex:index] objectForKey:@"thumb"]];
    }
    return nil;
}

+ (NSString *)saveImage:(UIImage*)image to:(NSString *)file
{
    //NSString *file = [NSString stringWithFormat:IMAGE_FORMAT, index];
    if (image != nil && file != nil)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString* path = [documentsDirectory stringByAppendingPathComponent:file];
        if([fileManager fileExistsAtPath:path])
        {
            return nil;
        }
        NSData* data = UIImageJPEGRepresentation(image, 0.85);
        [data writeToFile:path atomically:YES];
        return path;
    }
    return nil;
}

+ (void)saveImageToCameraRoll:(UIImage *)image
{
    if([(AppDelegate *)[UIApplication sharedApplication].delegate automaticallySaveToCameraRoll]) {
        UIImageWriteToSavedPhotosAlbum(image, self,
                                       @selector(image:finishedSavingWithError:contextInfo:),
                                       nil);
    }
}

+ (void)image:(UIImage *)image finishedSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"Saving to camera roll failed", nil)
                              message:NSLocalizedString(@"Please allow access to camera roll or disable automatic saving.", nil)
                              delegate: nil
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:nil];
        
        [alert show];
        [(AppDelegate *)[UIApplication sharedApplication].delegate setAutomaticallySaveToCameraRoll:NO];
    }
}

@end
