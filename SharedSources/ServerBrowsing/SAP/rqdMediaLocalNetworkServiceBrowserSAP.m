/*****************************************************************************
 * rqdMediaLocalNetworkServiceBrowserMediaDiscoverer.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


#import "rqdMediaLocalNetworkServiceBrowserSAP.h"
#import "rqdMediaLocalNetworkServiceVLCMedia.h"
@implementation rqdMediaLocalNetworkServiceBrowserSAP

- (instancetype)init {
    return [super initWithName:@"SAP"
            serviceServiceName:@"sap"];
}

- (id<rqdMediaLocalNetworkService>)networkServiceForIndex:(NSUInteger)index {
    VLCMedia *media = [self.mediaDiscoverer.discoveredMedia mediaAtIndex:index];
    if (media)
        return [[rqdMediaLocalNetworkServiceSAP alloc] initWithMediaItem:media serviceName:self.name];
    return nil;
}

@end


@implementation rqdMediaLocalNetworkServiceSAP
- (UIImage *)icon {
    return [UIImage imageNamed:@"TVBroadcastIcon"];
}
- (NSURL *)directPlaybackURL {

    VLCMediaType mediaType = self.mediaItem.mediaType;
    if (mediaType != VLCMediaTypeDirectory && mediaType != VLCMediaTypeDisc) {
        return [self.mediaItem url];
    }
    return nil;
}

@end
