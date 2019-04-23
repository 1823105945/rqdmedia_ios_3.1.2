/*****************************************************************************
 * rqdMediaLocalNetworkServiceBrowserPlex.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaLocalNetworkServiceBrowserNetService.h"

NS_ASSUME_NONNULL_BEGIN

@interface rqdMediaLocalNetworkServiceBrowserPlex : rqdMediaLocalNetworkServiceBrowserNetService
- (instancetype)initWithName:(NSString *)name serviceType:(NSString *)serviceType domain:(NSString *)domain NS_UNAVAILABLE;
- (instancetype)init NS_DESIGNATED_INITIALIZER;
@end


extern NSString *const rqdMediaNetworkServerProtocolIdentifierPlex;
@interface rqdMediaLocalNetworkServicePlex : rqdMediaLocalNetworkServiceNetService
@end

NS_ASSUME_NONNULL_END