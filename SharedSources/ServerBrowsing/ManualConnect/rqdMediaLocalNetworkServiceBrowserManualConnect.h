/*****************************************************************************
 * rqdMediaLocalNetworkServiceBrowserManualConnect.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaLocalNetworkServiceBrowser-Protocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface rqdMediaLocalNetworkServiceBrowserManualConnect : NSObject <rqdMediaLocalNetworkServiceBrowser>
- (instancetype)init;
@end


@interface rqdMediaLocalNetworkServiceItemLogin : NSObject <rqdMediaLocalNetworkService>
- (instancetype)initWithServiceName:(NSString *)serviceName;
@end

NS_ASSUME_NONNULL_END
