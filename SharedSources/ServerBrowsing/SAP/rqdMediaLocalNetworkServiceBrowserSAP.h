/*****************************************************************************
 * rqdMediaLocalNetworkServiceBrowserSAP.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaLocalNetworkServiceBrowserMediaDiscoverer.h"
#import "rqdMediaLocalNetworkServiceVLCMedia.h"

NS_ASSUME_NONNULL_BEGIN

@interface rqdMediaLocalNetworkServiceBrowserSAP : rqdMediaLocalNetworkServiceBrowserMediaDiscoverer
- (instancetype)init;
@end

@interface rqdMediaLocalNetworkServiceSAP: rqdMediaLocalNetworkServiceVLCMedia

@end

NS_ASSUME_NONNULL_END
