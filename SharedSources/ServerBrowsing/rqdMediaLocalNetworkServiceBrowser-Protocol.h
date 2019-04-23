/*****************************************************************************
 * rqdMediaLocalNetworkServiceBrowser-Protocol.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaLocalNetworkService-Protocol.h"

@protocol rqdMediaLocalNetworkServiceBrowserDelegate;
@protocol rqdMediaLocalNetworkServiceBrowser <NSObject>

@property (nonatomic, weak) id <rqdMediaLocalNetworkServiceBrowserDelegate> delegate;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSUInteger numberOfItems;
- (id<rqdMediaLocalNetworkService>)networkServiceForIndex:(NSUInteger)index;

- (void)startDiscovery;
- (void)stopDiscovery;
@end

@protocol rqdMediaLocalNetworkServiceBrowserDelegate <NSObject>
- (void) localNetworkServiceBrowserDidUpdateServices:(id<rqdMediaLocalNetworkServiceBrowser>)serviceBrowser;
@end
