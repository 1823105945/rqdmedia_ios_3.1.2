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

#import "rqdMediaRemoteBrowsingCollectionViewController.h"
#import "rqdMediaNetworkServerBrowser-Protocol.h"

NS_ASSUME_NONNULL_BEGIN
@interface rqdMediaServerBrowsingTVViewController : rqdMediaRemoteBrowsingCollectionViewController <rqdMediaNetworkServerBrowserDelegate>

@property (nonatomic) BOOL downloadArtwork;
@property (nonatomic, readonly) id<rqdMediaNetworkServerBrowser>serverBrowser;
@property (nonatomic, null_resettable) Class subdirectoryBrowserClass; // if not set returns [self class], must be subclass of rqdMediaServerBrowsingTVViewController

- (instancetype)initWithServerBrowser:(id<rqdMediaNetworkServerBrowser>)serverBrowser;

@end
NS_ASSUME_NONNULL_END
