/*****************************************************************************
 * rqdMediaSharedLibraryParser.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 *
 * Authors: Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

extern NSString *const rqdMediaSharedLibraryParserDeterminedNetserviceAsrqdMediaInstance;

@protocol rqdMediaSharedLibraryParserDelegate <NSObject>

@required

- (void)sharedLibraryDataProcessings:(NSArray *)result;

@end

@interface rqdMediaSharedLibraryParser : NSObject

@property (readwrite, weak) id<rqdMediaSharedLibraryParserDelegate> delegate;

- (void)checkNetserviceForrqdMediaService:(NSNetService *)netservice;
- (void)fetchDataFromServer:(NSString *)hostname port:(long)port;

@end
