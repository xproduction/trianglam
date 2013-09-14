//
//  Gallery.m
//  Photo
//
//  Created by Matěj Kašpar Jirásek on 28.11.12.
//  Copyright (c) 2012 X Production s.r.o. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>

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

+ (void)checkImagesIntegrity
{
    NSMutableArray *images = [self getMutableArray];
    NSArray *originalImages = [self getImageArray];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (id image in originalImages)
    {
        if (![fileManager fileExistsAtPath:[image objectForKey:@"thumb"]] || ![fileManager fileExistsAtPath:[image objectForKey:@"image"]])
        {
            NSError *error = nil;
            if (![fileManager fileExistsAtPath:[image objectForKey:@"thumb"]])
            {
                [fileManager removeItemAtPath:[image objectForKey:@"thumb"] error:&error];
            }
            if (error != nil)
            {
                NSLog(@"%@", error);
                error = nil;
            }
            
            if (![fileManager fileExistsAtPath:[image objectForKey:@"image"]])
            {
                [fileManager removeItemAtPath:[image objectForKey:@"image"] error:&error];
            }
            if (error != nil)
            {
                NSLog(@"%@", error);
            }
            
            [images removeObject:image];
        }
    }
    [self saveArray:images];
}

- (BOOL)addImage:(UIImage *)image location:(CLLocation *)location thumb:(UIImage *)thumb vector:(NSString *)vector
{
    if(image == nil || thumb == nil)
    {
        return NO;
    }
    double time = [[NSDate date] timeIntervalSince1970] * 1000.0;
    NSString *imageFilename = [Gallery saveImage:image to:[NSString stringWithFormat:IMAGE_FORMAT, time]];
    [self saveImageToCameraRoll:image location:location];
    NSString *thumbFilename = [Gallery saveImage:thumb to:[NSString stringWithFormat:THUMB_FORMAT, time]];
    //NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:imageFilename, @"image", thumbFilename, @"thumb", nil];
    NSDictionary *dictionary = @{@"image" : imageFilename, @"thumb" : thumbFilename, @"vector" : vector};
    NSMutableArray *array = [Gallery getMutableArray];
    [array addObject:dictionary];
    [Gallery saveArray:array];
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

- (BOOL)saveImageToCameraRoll:(UIImage *)image location:(CLLocation*)location
{
    if([(AppDelegate *)[UIApplication sharedApplication].delegate automaticallySaveToCameraRoll]) {
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        NSDictionary *gpsInfoDict;
        if (location != nil)
        {
            gpsInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:[Gallery getGPSDictionaryForLocation:location], @"{GPS}", nil];
        }
        
        NSData* data = UIImageJPEGRepresentation(image, 1.0);
        
        __block BOOL ret;

        [library writeImageDataToSavedPhotosAlbum:data metadata:gpsInfoDict completionBlock:^(NSURL *assetURL, NSError *error) {
            if (error) {
                [self image:image finishedSavingWithError:error contextInfo:nil];
                ret = NO;
            } else {
                ret = YES;
            }
        }];
        
        return ret;
    } else return YES;
}

- (void)image:(UIImage *)image finishedSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
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

+ (NSDictionary *)getGPSDictionaryForLocation:(CLLocation *)location {
    NSMutableDictionary *gps = [NSMutableDictionary dictionary];
    
    // GPS tag version
    [gps setObject:@"2.2.0.0" forKey:(NSString *)kCGImagePropertyGPSVersion];
    
    // Time and date must be provided as strings, not as an NSDate object
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss.SSSSSS"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [gps setObject:[formatter stringFromDate:location.timestamp] forKey:(NSString *)kCGImagePropertyGPSTimeStamp];
    [formatter setDateFormat:@"yyyy:MM:dd"];
    [gps setObject:[formatter stringFromDate:location.timestamp] forKey:(NSString *)kCGImagePropertyGPSDateStamp];
    
    // Latitude
    CGFloat latitude = location.coordinate.latitude;
    if (latitude < 0) {
        latitude = -latitude;
        [gps setObject:@"S" forKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
    } else {
        [gps setObject:@"N" forKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
    }
    [gps setObject:[NSNumber numberWithFloat:latitude] forKey:(NSString *)kCGImagePropertyGPSLatitude];
    
    // Longitude
    CGFloat longitude = location.coordinate.longitude;
    if (longitude < 0) {
        longitude = -longitude;
        [gps setObject:@"W" forKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
    } else {
        [gps setObject:@"E" forKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
    }
    [gps setObject:[NSNumber numberWithFloat:longitude] forKey:(NSString *)kCGImagePropertyGPSLongitude];
    
    // Altitude
    CGFloat altitude = location.altitude;
    if (!isnan(altitude)){
        if (altitude < 0) {
            altitude = -altitude;
            [gps setObject:@"1" forKey:(NSString *)kCGImagePropertyGPSAltitudeRef];
        } else {
            [gps setObject:@"0" forKey:(NSString *)kCGImagePropertyGPSAltitudeRef];
        }
        [gps setObject:[NSNumber numberWithFloat:altitude] forKey:(NSString *)kCGImagePropertyGPSAltitude];
    }
    
    // Speed, must be converted from m/s to km/h
    if (location.speed >= 0){
        [gps setObject:@"K" forKey:(NSString *)kCGImagePropertyGPSSpeedRef];
        [gps setObject:[NSNumber numberWithFloat:location.speed*3.6] forKey:(NSString *)kCGImagePropertyGPSSpeed];
    }
    
    // Heading
    if (location.course >= 0){
        [gps setObject:@"T" forKey:(NSString *)kCGImagePropertyGPSTrackRef];
        [gps setObject:[NSNumber numberWithFloat:location.course] forKey:(NSString *)kCGImagePropertyGPSTrack];
    }
    
    return gps;
}

@end
