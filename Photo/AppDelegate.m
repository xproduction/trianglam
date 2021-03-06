//
//  AppDelegate.m
//  Photo
//
//  Created by Matěj Kašpar Jirásek on 27.11.12.
//  Copyright (c) 2012 X Production s.r.o. All rights reserved.
//

#import "AppDelegate.h"
#import "Flurry.h"

@implementation AppDelegate

@synthesize automaticallySaveToCameraRoll, cameraController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //[Flurry setDebugLogEnabled:YES];
    [Flurry setCrashReportingEnabled:YES];
    //[Flurry setEventLoggingEnabled:YES];
    [Flurry startSession:@"VD9RF33942GTFK38R5D2"];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
   
    cameraController = [[CameraViewController alloc] init];
    galleryController = [[GalleryViewController alloc] init];
    
    automaticallySaveToCameraRoll = YES;    
    
    self.window.rootViewController = cameraController;
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)transitionToGallery
{
    [Flurry logEvent:@"Went to gallery"];
    
    if (self.window.rootViewController.view == cameraController.view)
    {
        [UIView transitionFromView:self.window.rootViewController.view
                            toView:galleryController.view
                          duration:0.4f
                           options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionTransitionFlipFromRight
                        completion:^(BOOL finished){
                            self.window.rootViewController = galleryController;
                        }];
    }
}
- (void)transitionToCamera
{
    [Flurry logEvent:@"Went to camera"];
    
    if (self.window.rootViewController.view == galleryController.view)
    {
        [UIView transitionFromView:self.window.rootViewController.view
                        toView:cameraController.view
                      duration:0.4f
                       options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionTransitionFlipFromLeft
                    completion:^(BOOL finished){
                        self.window.rootViewController = cameraController;
                    }];
    }
}

@end
