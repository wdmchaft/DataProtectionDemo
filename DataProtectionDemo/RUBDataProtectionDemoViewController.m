//
//  DataProtectionDemoViewController.m
//  DataProtectionDemo
//
//  Created by Manuel Binna on 18.03.11.
//  Copyright 2011 Manuel Binna. All rights reserved.
//

#import "RUBDataProtectionDemoViewController.h"
#import <Security/Security.h>

#define kKeychainItemIdentifier @"de.rub.emma.DataProtectionDemo"
#define kKeychainItemServer @"www.example.com"
#define kKeychainItemAccount @"USERNAME"
#define kKeychainItemPassword @"S3Cret_P4ssC0de!"
#define kKeychainItemDescription @"DataProtectionDemo sample application"


@interface RUBDataProtectionDemoViewController ()

@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

- (void)registerForNotifications;
- (void)unregisterForNotifications;
- (void)protectedDataDidBecomeAvailable:(NSNotification *)notification;
- (void)protectedDataWillBecomeUnavailable:(NSNotification *)notification;

- (BOOL)copySecretContentFromMainBundleToDocumentDirectoryImmediateProtection;
- (BOOL)copySecretContentFromMainBundleToDocumentDirectoryDelayedProtection;
- (void)removeProtectionOfProtectedFile;

- (void)addItemToKeychain;
- (void)updateKeychainItemWithProtectionClass:(CFTypeRef)accessibilityClass;
- (NSDictionary *)retrieveKeychainItem;
- (NSMutableDictionary *)keychainItemSearchDictionary;
- (void)removeItemFromKeychain;

- (void)logValuesOfAllProtectionClasses;
- (NSString *)documentDirectoryPath ;

@end


@implementation RUBDataProtectionDemoViewController

@synthesize backgroundTaskIdentifier = _backgroundTaskIdentifier;

#pragma mark NSObject

- (void)dealloc
{
    [self unregisterForNotifications];
    
    [super dealloc];
}

#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self registerForNotifications];
    
    [self logValuesOfAllProtectionClasses];
    
    [self copySecretContentFromMainBundleToDocumentDirectoryImmediateProtection];
    [self copySecretContentFromMainBundleToDocumentDirectoryDelayedProtection];
    [self removeProtectionOfProtectedFile];
    
    [self addItemToKeychain];
    [self retrieveKeychainItem];
    [self updateKeychainItemWithProtectionClass:kSecAttrAccessibleAfterFirstUnlock];
    [self retrieveKeychainItem];
    [self removeItemFromKeychain];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

#pragma mark RUBDataProtectionDemoViewController

- (void)registerForNotifications
{
    NSNotificationCenter *notifictionCenter = [NSNotificationCenter defaultCenter];
    
    [notifictionCenter addObserver:self 
                          selector:@selector(protectedDataDidBecomeAvailable:) 
                              name:UIApplicationProtectedDataDidBecomeAvailable
                            object:nil];
    
    
    [notifictionCenter addObserver:self 
                          selector:@selector(protectedDataWillBecomeUnavailable:) 
                              name:UIApplicationProtectedDataWillBecomeUnavailable 
                            object:nil];
}

- (void)unregisterForNotifications
{
    NSNotificationCenter *notifictionCenter = [NSNotificationCenter defaultCenter];
    
    [notifictionCenter removeObserver:self 
                                 name:UIApplicationProtectedDataDidBecomeAvailable 
                               object:nil];
    
    [notifictionCenter removeObserver:self 
                                 name:UIApplicationProtectedDataWillBecomeUnavailable
                               object:nil];
}

- (void)protectedDataDidBecomeAvailable:(NSNotification *)notification
{
    NSLog(@"Protected data did become available");
}

- (void)protectedDataWillBecomeUnavailable:(NSNotification *)notification
{
    NSLog(@"Protected data will become unavailable");
    
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    NSString *protectedFilePath = [documentDirectory stringByAppendingPathComponent:@"SecretContent_NSDataWritingFileProtectionComplete.txt"];
    
    // Access protected data (device is currently unlocked)
    NSData *protectedAvailableData = [NSData dataWithContentsOfFile:protectedFilePath];
    NSString *protectedAvailableContent = [[NSString alloc] initWithData:protectedAvailableData encoding:NSUTF8StringEncoding];
    NSLog(@"[UNLOCKED DEVICE] Content of protected data: %@", protectedAvailableContent);
    [protectedAvailableContent release];
    
    // Register the expiration handler
    UIApplication *application = [UIApplication sharedApplication];
    __block typeof(self) blockSelf = self;
    self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:blockSelf.backgroundTaskIdentifier];
        blockSelf.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }];
    
    // Schedule a task to be started in 20 seconds from now.
    // 20 seconds is pretty long, we just want to be sure that the device is really locked.
    double delayInSeconds = 20.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Access protected data (device is currently locked)
        NSData *protectedUnavailableData = [NSData dataWithContentsOfFile:protectedFilePath];
        NSString *protectedUnavailableContent = [[NSString alloc] initWithData:protectedUnavailableData encoding:NSUTF8StringEncoding];
        NSLog(@"[LOCKED DEVICE] Content of protected data: %@", protectedUnavailableContent);
        [protectedUnavailableContent release];
        
        [blockSelf retrieveKeychainItem];
        
        // End task
        [application endBackgroundTask:blockSelf.backgroundTaskIdentifier];
        blockSelf.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    });
}

- (BOOL)copySecretContentFromMainBundleToDocumentDirectoryImmediateProtection
{
    NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"SecretContent" 
                                                           ofType:@"txt"];
    NSData *plaintextData = [NSData dataWithContentsOfFile:sourcePath];
    
    NSString *destinationPath = [[self documentDirectoryPath] 
                                 stringByAppendingPathComponent:@"SecretContent_NSDataWritingFileProtectionComplete.txt"];
    
    NSError *error = nil;
    BOOL successful = [plaintextData writeToFile:destinationPath 
                                         options:NSDataWritingFileProtectionComplete 
                                           error:&error];
    if (!successful) 
    {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    return successful;
}

- (BOOL)copySecretContentFromMainBundleToDocumentDirectoryDelayedProtection
{
    NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"SecretContent" 
                                                           ofType:@"txt"];
    NSData *plaintextData = [NSData dataWithContentsOfFile:sourcePath];
    
    NSString *destinationPath = [[self documentDirectoryPath] 
                                 stringByAppendingPathComponent:@"SecretContent_NSFileProtectionComplete.txt"];
    
    NSError *error = nil;
    BOOL successful = [plaintextData writeToFile:destinationPath 
                                         options:0 
                                           error:&error];
    if (!successful) 
    {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    // Set extended attribute to protect file
    NSDictionary *protectionAttribute = [NSDictionary dictionaryWithObject:NSFileProtectionComplete 
                                                                    forKey:NSFileProtectionKey];
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    successful = [fileManager setAttributes:protectionAttribute 
                               ofItemAtPath:destinationPath 
                                      error:&error];
    if (!successful) 
    {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    return successful;
}

- (void)removeProtectionOfProtectedFile
{
    NSString *filePath = [[self documentDirectoryPath] 
                          stringByAppendingPathComponent:@"SecretContent_NSFileProtectionComplete.txt"];
    
    // Set extended attribute to protect file
    NSDictionary *protectionAttribute = [NSDictionary dictionaryWithObject:NSFileProtectionNone
                                                                    forKey:NSFileProtectionKey];
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    NSError *error = nil;
    BOOL successful = [fileManager setAttributes:protectionAttribute 
                                    ofItemAtPath:filePath 
                                           error:&error];
    if (!successful) 
    {
        NSLog(@"%@", [error localizedDescription]);
    }
}

- (void)addItemToKeychain
{
    NSMutableDictionary *attributes = [self keychainItemSearchDictionary];
    
    OSStatus searchResult = SecItemCopyMatching((CFDictionaryRef)attributes, 
                                                NULL);
    if (searchResult == errSecItemNotFound) // Keychain item does not exist yet. Create it.
    {   
        [attributes setObject:kKeychainItemAccount 
                       forKey:kSecAttrAccount];
        [attributes setObject:kSecAttrAccessibleWhenUnlocked
                       forKey:kSecAttrAccessible];
        [attributes setObject:[kKeychainItemPassword dataUsingEncoding:NSUTF8StringEncoding] 
                       forKey:kSecValueData];

        OSStatus status = SecItemAdd((CFDictionaryRef) attributes, 
                                     NULL);
        if (status != errSecSuccess) 
        {
            // Error
            NSLog(@"Error: %ld", status);
        }
    }
}

- (void)updateKeychainItemWithProtectionClass:(CFTypeRef)accessibilityClass
{
    // Update the item. Requires the item data!
    NSMutableDictionary *query = [self keychainItemSearchDictionary];
    NSData *itemData = [kKeychainItemPassword dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *updatedAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                       (id)accessibilityClass, (id)kSecAttrAccessible,
                                       (CFDataRef)itemData, (id)kSecValueData,
                                       nil];
    OSStatus updateStatus = SecItemUpdate((CFDictionaryRef)query, 
                                          (CFDictionaryRef)updatedAttributes);
    if (updateStatus != errSecSuccess) 
    {
        // Error
        NSLog(@"Error: %ld", updateStatus);
    }
}

- (NSDictionary *)retrieveKeychainItem
{
    NSMutableDictionary *searchDictionary = [self keychainItemSearchDictionary];
    [searchDictionary setObject:(id)kCFBooleanTrue 
                         forKey:kSecReturnAttributes];
    [searchDictionary setObject:(id)kCFBooleanTrue 
                         forKey:kSecReturnData];
    
    NSDictionary *keychainItem = nil;
    SecItemCopyMatching((CFDictionaryRef)searchDictionary, 
                        (CFTypeRef *)&keychainItem);
        
    return keychainItem;
}

- (NSMutableDictionary *)keychainItemSearchDictionary
{
    NSData *encodedIdentifier = [kKeychainItemIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            kSecClassGenericPassword, kSecClass,
            encodedIdentifier, (id)kSecAttrGeneric,
            encodedIdentifier, (id)kSecAttrService,
            nil];
}

- (void)removeItemFromKeychain
{
    NSMutableDictionary *searchDictionary = [self keychainItemSearchDictionary];
    SecItemDelete((CFDictionaryRef)searchDictionary);
}

- (void)logValuesOfAllProtectionClasses
{
    NSLog(@"kSecAttrAccessibleAlways: %@", kSecAttrAccessibleAlways);
    NSLog(@"kSecAttrAccessibleAlwaysThisDeviceOnly: %@", kSecAttrAccessibleAlwaysThisDeviceOnly);
    NSLog(@"kSecAttrAccessibleAfterFirstUnlock: %@", kSecAttrAccessibleAfterFirstUnlock);
    NSLog(@"kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly: %@", kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly);
    NSLog(@"kSecAttrAccessibleWhenUnlocked: %@", kSecAttrAccessibleWhenUnlocked);
    NSLog(@"kSecAttrAccessibleWhenUnlockedThisDeviceOnly: %@", kSecAttrAccessibleWhenUnlockedThisDeviceOnly);
}

- (NSString *)documentDirectoryPath 
{    
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
                                                                       NSUserDomainMask, 
                                                                       YES);
    return [documentDirectories objectAtIndex:0];
}

@end
