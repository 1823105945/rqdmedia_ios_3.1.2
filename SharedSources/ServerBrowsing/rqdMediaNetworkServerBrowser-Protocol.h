/*****************************************************************************
 * rqdMediaNetworkServerBrowser-Protocol.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015-2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol rqdMediaNetworkServerBrowserItem;
@protocol rqdMediaNetworkServerBrowserDelegate;

@protocol rqdMediaNetworkServerBrowser <NSObject>

@required
@property (nonatomic, weak) id <rqdMediaNetworkServerBrowserDelegate> delegate;
@property (nonatomic, readonly, nullable) NSString *title;
@property (nonatomic, readonly, copy) VLCMediaList *mediaList;
@property (nonatomic, copy, readonly) NSArray<id<rqdMediaNetworkServerBrowserItem>> *items;

- (void)update;

@end

@protocol rqdMediaNetworkServerBrowserDelegate <NSObject>
- (void) networkServerBrowserDidUpdate:(id<rqdMediaNetworkServerBrowser>)networkBrowser;
- (void) networkServerBrowser:(id<rqdMediaNetworkServerBrowser>)networkBrowser requestDidFailWithError:(NSError *)error;
@end


@protocol rqdMediaNetworkServerBrowserItem <NSObject>
@required
@property (nonatomic, readonly, getter=isContainer) BOOL container;
// if item is container browser is the browser for the container
@property (nonatomic, readonly, nullable) id<rqdMediaNetworkServerBrowser> containerBrowser;

@property (nonatomic, readonly, nullable) VLCMedia *media;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly, nullable) NSURL *URL;
@property (nonatomic, readonly, nullable) NSNumber *fileSizeBytes;

@optional
@property (nonatomic, readonly, nullable) NSString *filename;
@property (nonatomic, readonly, nullable) NSString *duration;
@property (nonatomic, readonly, nullable) NSString *subtitleType;
@property (nonatomic, readonly, nullable) NSURL *subtitleURL;
@property (nonatomic, readonly, nullable) NSURL *thumbnailURL;
@property (nonatomic, getter=isDownloadable, readonly) BOOL downloadable;
@end


NS_ASSUME_NONNULL_END
