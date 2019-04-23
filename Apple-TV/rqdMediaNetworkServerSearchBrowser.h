/*****************************************************************************
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Vincent L. Cone <vincent.l.cone # tuta.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


#import <UIKit/UIKit.h>
#import "rqdMediaNetworkServerBrowser-Protocol.h"

NS_ASSUME_NONNULL_BEGIN
@interface rqdMediaNetworkServerSearchBrowser : NSObject <rqdMediaNetworkServerBrowser, rqdMediaNetworkServerBrowserDelegate>
// change the searchText to update the filters
@property (nonatomic, copy, nullable) NSString *searchText;
// rqdMediaNetworkServerSearchBrowser does not set itself as the delegate of the serverBrowser,
// instead the delegate of the serverBrowser has to relay the delegate methods to rqdMediaNetworkServerSearchBrowser while active.
- (instancetype)initWithServerBrowser:(id<rqdMediaNetworkServerBrowser>)serverBrowser;
@end
NS_ASSUME_NONNULL_END
