//
// Prefix header for all source files of the 'TVHeadend iPhone Client' target in the 'TVHeadend iPhone Client' project
//

#import <Availability.h>

#ifndef __IPHONE_5_0
#warning "This project uses features only available in iOS SDK 5.0 and later."
#endif

//#define TESTING
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#ifdef __IPHONE_7_0
#define DEVICE_HAS_IOS7 SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")
#else
#define DEVICE_HAS_IOS7 NO
#endif
#define SYSTEM_RUNS_IOS7_OR_LATER DEVICE_HAS_IOS7

#ifdef __IPHONE_8_0
#define DEVICE_HAS_IOS8 SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")
#else
#define DEVICE_HAS_IOS8 NO
#endif

#ifdef __OBJC__
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <MobileCoreServices/MobileCoreServices.h>
//#import "TVHApiKeys.h"
//#import "NSDate+Utilities.h"
#import "TVHStatusBar.h"
#if defined TVH_CRASHLYTICS_KEY && !defined TESTING
#import <Crashlytics/Crashlytics.h>
#define NSLog(__FORMAT__, ...) CLSLog((@"%s line %d $ " __FORMAT__), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#endif
#define APLog NSLog
#import "TVHAnalytics.h"
#endif
