/*****************************************************************************
 * rqdMediaLocalNetworkServiceBrowserPlex.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaLocalNetworkServiceBrowserPlex.h"
#import "rqdMediaNetworkServerBrowserPlex.h"

@implementation rqdMediaLocalNetworkServiceBrowserPlex
- (instancetype)init {
#if TARGET_OS_TV
    NSString *name = NSLocalizedString(@"PLEX_SHORT",nil);
#else
    NSString *name = NSLocalizedString(@"PLEX_LONG",nil);
#endif
    return [super initWithName:name
                   serviceType:@"_plexmediasvr._tcp."
                        domain:@""];
}
- (rqdMediaLocalNetworkServiceNetService *)localServiceForNetService:(NSNetService *)netService {
    return [[rqdMediaLocalNetworkServicePlex alloc] initWithNetService:netService serviceName:self.name];
}
@end

NSString *const rqdMediaNetworkServerProtocolIdentifierPlex = @"plex";

@implementation rqdMediaLocalNetworkServicePlex
- (UIImage *)icon {
    return [UIImage imageNamed:@"PlexServerIcon"];
}
- (id<rqdMediaNetworkServerBrowser>)serverBrowser {

    NSNetService *service = self.netService;
    if (service.hostName == nil || service.port == 0) {
        return nil;
    }

    NSString *name = service.name;
    NSString *hostName = service.hostName;
    NSUInteger portNum = service.port;
    rqdMediaNetworkServerBrowserPlex *serverBrowser = [[rqdMediaNetworkServerBrowserPlex alloc] initWithName:name host:hostName portNumber:@(portNum) path:@"" authentificication:@""];

    return serverBrowser;
}
@end

