/*****************************************************************************
 * rqdMediaLocalNetworkServiceBrowserHTTP.h
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
#import "rqdMediaLocalNetworkServiceNetService.h"

NS_ASSUME_NONNULL_BEGIN

@interface rqdMediaLocalNetworkServiceBrowserHTTP : rqdMediaLocalNetworkServiceBrowserNetService
- (instancetype)initWithName:(NSString *)name serviceType:(NSString *)serviceType domain:(NSString *)domain NS_UNAVAILABLE;
- (instancetype)init NS_DESIGNATED_INITIALIZER;
@end

@interface rqdMediaLocalNetworkServiceHTTP : rqdMediaLocalNetworkServiceNetService

@end

NS_ASSUME_NONNULL_END