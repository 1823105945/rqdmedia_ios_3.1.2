/*****************************************************************************
 * rqdMediaNetworkServerBrowserFTP.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaNetworkServerBrowser-Protocol.h"
#import "rqdMediaNetworkServerLoginInformation.h"

NS_ASSUME_NONNULL_BEGIN

@interface rqdMediaNetworkServerBrowserFTP : NSObject <rqdMediaNetworkServerBrowser>
- (instancetype)initWithLogin:(rqdMediaNetworkServerLoginInformation *)login;
- (instancetype)initWithFTPServer:(NSString *)serverAddress userName:(nullable NSString *)username andPassword:(nullable NSString *)password atPath:(NSString *)path;
- (instancetype)initWithURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface rqdMediaNetworkServerBrowserItemFTP : NSObject <rqdMediaNetworkServerBrowserItem>

- (instancetype)initWithDictionary:(NSDictionary *)dict baseURL:(NSURL *)baseURL subtitleURL:(NSURL *)subtitleURL;

@property (nonatomic, readwrite) NSArray<id<rqdMediaNetworkServerBrowserItem>> *items;
@property (nonatomic, getter=isDownloadable, readonly) BOOL downloadable;
@property (nonatomic, readonly, nullable) NSURL *subtitleURL;

@end

NS_ASSUME_NONNULL_END
