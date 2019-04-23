/*****************************************************************************
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>
#import "rqdMediaNetworkServerBrowser-Protocol.h"

#define DOWNLOAD_SUPPORTED TARGET_OS_IOS

NS_ASSUME_NONNULL_BEGIN
@protocol rqdMediaRemoteBrowsingCell <NSObject>

@property (nonatomic, nullable) NSString *title;
@property (nonatomic, nullable) NSString *subtitle;
@property (nonatomic, nullable) UIImage *thumbnailImage;
@property (nonatomic, nullable) NSURL *thumbnailURL;
@property (nonatomic) BOOL isDirectory;
@property (nonatomic) BOOL couldBeAudioOnlyMedia;
#if DOWNLOAD_SUPPORTED
@property (nonatomic) BOOL isDownloadable;
#endif
@end


@interface rqdMediaServerBrowsingController : NSObject
@property (nonatomic, nullable) NSByteCountFormatter *byteCountFormatter;
@property (nonatomic, nullable) UIImage *folderImage;
@property (nonatomic, nullable) UIImage *genericFileImage;

@property (nonatomic, readonly) id<rqdMediaNetworkServerBrowser> serverBrowser;
@property (nonatomic, weak, nullable, readonly) UIViewController *viewController;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithViewController:(UIViewController *)viewController serverBrowser:(id<rqdMediaNetworkServerBrowser>)browser;

- (void)configureCell:(id<rqdMediaRemoteBrowsingCell>)cell withItem:(id<rqdMediaNetworkServerBrowserItem>)item;

#pragma mark - Subtitles
- (void)configureSubtitlesInMediaList:(VLCMediaList *)mediaList;
#pragma mark - Streaming
- (void)streamFileForItem:(id<rqdMediaNetworkServerBrowserItem>)item;
- (void)streamMediaList:(VLCMediaList *)mediaList startingAtIndex:(NSInteger)startIndex;


#if DOWNLOAD_SUPPORTED
- (BOOL)triggerDownloadForItem:(id<rqdMediaNetworkServerBrowserItem>)item;

#endif
@end
NS_ASSUME_NONNULL_END

