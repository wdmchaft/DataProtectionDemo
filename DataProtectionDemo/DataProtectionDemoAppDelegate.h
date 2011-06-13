//
//  DataProtectionDemoAppDelegate.h
//  DataProtectionDemo
//
//  Created by Manuel Binna on 18.03.11.
//  Copyright 2011 Manuel Binna. All rights reserved.
//

@class RUBDataProtectionDemoViewController;

@interface DataProtectionDemoAppDelegate : NSObject <UIApplicationDelegate> 
{

}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet RUBDataProtectionDemoViewController *viewController;

@end
