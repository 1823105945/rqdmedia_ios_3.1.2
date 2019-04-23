/*****************************************************************************
 * rqdMediaLocalNetworkServiceBrowserBonjour.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015-2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/
#import "rqdMediaLocalNetworkServiceVLCMedia.h"
#import "rqdMediaNetworkServerBrowserVLCMedia.h"
#import "rqdMediaLocalNetworkServiceBrowserMediaDiscoverer.h"
#import "rqdMediaNetworkServerLoginInformation.h"

NS_ASSUME_NONNULL_BEGIN

@interface rqdMediaLocalNetworkServiceBrowserBonjour : rqdMediaLocalNetworkServiceBrowserMediaDiscoverer
- (instancetype)init;
@end

extern NSString *const rqdMediaNetworkServerProtocolIdentifierBonjour;
@interface rqdMediaLocalNetworkServiceBonjour: rqdMediaLocalNetworkServiceVLCMedia

@end

@interface rqdMediaNetworkServerBrowserVLCMedia (Bonjour)

@end

NS_ASSUME_NONNULL_END
