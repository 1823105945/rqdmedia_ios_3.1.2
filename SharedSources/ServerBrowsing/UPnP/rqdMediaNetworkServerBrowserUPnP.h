/*****************************************************************************
 * rqdMediaNetworkServerBrowserUPnP.h
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

#define krqdMediaUPnPVideoProtocolKey @"http-get:*:video/"
#define krqdMediaUPnPAudioProtocolKey @"http-get:*:audio/"

NS_ASSUME_NONNULL_BEGIN
@class MediaServer1Device;
@interface rqdMediaNetworkServerBrowserUPnP : NSObject <rqdMediaNetworkServerBrowser>
- (id)initWithUPNPDevice:(MediaServer1Device *)device header:(NSString *)header andRootID:(NSString *)rootID NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
@end


@class MediaServer1BasicObject;
@interface rqdMediaNetworkServerBrowserItemUPnP : NSObject <rqdMediaNetworkServerBrowserItem>
- (instancetype)initWithBasicObject:(MediaServer1BasicObject *)basicObject device:(MediaServer1Device *)device;
@property (nonatomic, readonly, nullable) NSString *duration;
@property (nonatomic, readonly, nullable) NSURL *subtitleURL;
@property (nonatomic, readonly, nullable) NSURL *thumbnailURL;
@property (nonatomic, getter=isDownloadable, readonly) BOOL downloadable;

// UPnP specificis
@property (nonatomic, readonly, nullable) UIImage *image;
@end


#pragma mark - Multi Ressource
@class MediaServer1ItemObject;
@interface rqdMediaNetworkServerBrowserUPnPMultiRessource : NSObject <rqdMediaNetworkServerBrowser>
- (instancetype)initWithItem:(MediaServer1ItemObject *)itemObject device:(MediaServer1Device *)device;
@end

@interface rqdMediaNetworkServerBrowserItemUPnPMultiRessource : NSObject <rqdMediaNetworkServerBrowserItem>
- (instancetype)initWithTitle:(NSString *)title url:(NSURL *)url;
@end


NS_ASSUME_NONNULL_END
