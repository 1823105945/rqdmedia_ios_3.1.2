/*****************************************************************************
 * rqdMediaLocalNetworkServiceBrowserDSM.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/
#import "rqdMediaLocalNetworkServiceVLCMedia.h"
#import "rqdMediaNetworkServerBrowserVLCMedia.h"
#import "rqdMediaLocalNetworkServiceBrowserMediaDiscoverer.h"
#import "rqdMediaNetworkServerLoginInformation.h"

NS_ASSUME_NONNULL_BEGIN

@interface rqdMediaLocalNetworkServiceBrowserDSM : rqdMediaLocalNetworkServiceBrowserMediaDiscoverer
- (instancetype)init;
@end

extern NSString *const rqdMediaNetworkServerProtocolIdentifierSMB;
@interface rqdMediaLocalNetworkServiceDSM: rqdMediaLocalNetworkServiceVLCMedia

@end

@interface rqdMediaNetworkServerBrowserVLCMedia (SMB)
+ (instancetype)SMBNetworkServerBrowserWithLogin:(rqdMediaNetworkServerLoginInformation *)login;
+ (instancetype)SMBNetworkServerBrowserWithURL:(NSURL *)url
									  username:(nullable NSString *)username
									  password:(nullable NSString *)password
									 workgroup:(nullable NSString *)workgroup;

@end

NS_ASSUME_NONNULL_END
