//
//  DataProtectionDemoAppDelegate.m
//  DataProtectionDemo
//
//  Created by Manuel Binna on 18.03.11.
//  Copyright 2011 Manuel Binna. All rights reserved.
//

#import "DataProtectionDemoAppDelegate.h"
#import "RUBDataProtectionDemoViewController.h"


@implementation DataProtectionDemoAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    BOOL protectedDataAvailable = [[UIApplication sharedApplication] isProtectedDataAvailable];
    NSLog(@"protectedDataAvailable: %@", protectedDataAvailable ? @"YES" : @"NO");
     
    [[self window] setRootViewController:[self viewController]];
    [[self window] makeKeyAndVisible];
    return YES;
}

- (void)applicationProtectedDataDidBecomeAvailable:(UIApplication *)application
{
    NSLog(@"applicationProtectedDataDidBecomeAvailable:");
}

- (void)applicationProtectedDataWillBecomeUnavailable:(UIApplication *)application
{
    NSLog(@"applicationProtectedDataWillBecomeUnavailable:");
}

- (void)dealloc
{
    [_window release];
    [_viewController release];
    
    [super dealloc];
}

@end
