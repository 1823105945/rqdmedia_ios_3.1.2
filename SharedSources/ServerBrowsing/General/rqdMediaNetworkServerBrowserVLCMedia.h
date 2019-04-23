/*****************************************************************************
 * rqdMediaNetworkServerBrowserVLCMedia.h
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

NS_ASSUME_NONNULL_BEGIN
@interface rqdMediaNetworkServerBrowserVLCMedia : NSObject <rqdMediaNetworkServerBrowser>
- (instancetype)initWithMedia:(VLCMedia *)media options:(NSDictionary *)options NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface rqdMediaNetworkServerBrowserItemVLCMedia : NSObject <rqdMediaNetworkServerBrowserItem>
- (instancetype)initWithMedia:(VLCMedia *)media options:(NSDictionary *)mediaOptions;

@property (nonatomic, getter=isDownloadable, readonly) BOOL downloadable;

@end

NS_ASSUME_NONNULL_END