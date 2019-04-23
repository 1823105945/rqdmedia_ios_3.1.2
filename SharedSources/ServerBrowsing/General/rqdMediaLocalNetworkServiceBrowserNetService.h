/*****************************************************************************
 * rqdMediaLocalNetworkServiceBrowserNetService.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import "rqdMediaLocalNetworkServiceBrowser-Protocol.h"
#import "rqdMediaLocalNetworkServiceNetService.h"

@interface rqdMediaLocalNetworkServiceBrowserNetService : NSObject <rqdMediaLocalNetworkServiceBrowser>
- (instancetype)initWithName:(NSString *)name serviceType:(NSString *)serviceType domain:(NSString *)domain NS_DESIGNATED_INITIALIZER;
@property (nonatomic, weak) id<rqdMediaLocalNetworkServiceBrowserDelegate> delegate;
@end

@interface rqdMediaLocalNetworkServiceBrowserNetService() <NSNetServiceBrowserDelegate, NSNetServiceDelegate>
@property (nonatomic, readonly) NSNetServiceBrowser *netServiceBrowser;
@property (nonatomic, readonly) NSString *serviceType;
@property (nonatomic, readonly) NSString *domain;

@property (nonatomic, readonly, getter=isDiscovering) BOOL discovering;

@property (nonatomic, readonly) NSMutableArray<NSNetService*> *rawNetServices;
@property (nonatomic, readonly) NSMutableArray<rqdMediaLocalNetworkServiceNetService*> *resolvedLocalNetworkServices;

// adds netservice and informs delegate
- (void)addResolvedLocalNetworkService:(rqdMediaLocalNetworkServiceNetService *)localNetworkService;

// override in subclasses for different configurations
- (rqdMediaLocalNetworkServiceNetService *)localServiceForNetService:(NSNetService *)netService;
- (void)netServiceDidResolveAddress:(NSNetService *)sender;
@end
