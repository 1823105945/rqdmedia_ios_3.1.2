/*****************************************************************************
 * rqdMediaLocalNetworkServiceBrowserBonjour.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaLocalNetworkServiceBrowserBonjour.h"
#import "rqdMediaNetworkServerLoginInformation.h"


@implementation rqdMediaLocalNetworkServiceBrowserBonjour

- (instancetype)init
{
    NSString *name = NSLocalizedString(@"BONJOUR_FILE_SERVERS", nil);

    self.mediaDiscoverer.libraryInstance.debugLogging = YES;

    return [super initWithName:name serviceServiceName:@"bonjour"];
}

- (id<rqdMediaLocalNetworkService>)networkServiceForIndex:(NSUInteger)index
{
    VLCMedia *media = [self.mediaDiscoverer.discoveredMedia mediaAtIndex:index];
    NSString *serviceName = media.url.scheme;
    if (media)
        return [[rqdMediaLocalNetworkServiceBonjour alloc] initWithMediaItem:media serviceName:serviceName];
    return nil;
}

@end

NSString *const rqdMediaNetworkServerProtocolIdentifierBonjour = @"Bonjour";

@implementation rqdMediaLocalNetworkServiceBonjour

- (UIImage *)icon
{
    return [UIImage imageNamed:@"serverIcon"];
}

@end
