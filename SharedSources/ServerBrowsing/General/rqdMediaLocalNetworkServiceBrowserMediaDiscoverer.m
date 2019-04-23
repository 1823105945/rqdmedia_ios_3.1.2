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


#import "rqdMediaLocalNetworkServiceBrowserMediaDiscoverer.h"
#import "rqdMediaLocalNetworkServiceVLCMedia.h"

@interface rqdMediaLocalNetworkServiceBrowserMediaDiscoverer () <VLCMediaListDelegate>
@property (nonatomic, readonly) NSString *serviceName;
@property (nonatomic, readwrite) VLCMediaDiscoverer* mediaDiscoverer;

@end

@implementation rqdMediaLocalNetworkServiceBrowserMediaDiscoverer
@synthesize name = _name, delegate = _delegate;

- (instancetype)initWithName:(NSString *)name serviceServiceName:(NSString *)serviceName
{
    self = [super init];
    if (self) {
        _name = name;
        _serviceName = serviceName;
    }
    return self;
}
- (instancetype)init {
    return [self initWithName:@"" serviceServiceName:@""];
}

- (void)startDiscovery
{
    // don't start discovery twice
    if (self.mediaDiscoverer) {
        return;
    }
    VLCMediaDiscoverer *discoverer = [[VLCMediaDiscoverer alloc] initWithName:self.serviceName];
    self.mediaDiscoverer = discoverer;
    /* enable this boolean to debug the discovery session
     * note that this will not necessarily enable debug for playback */
#ifndef NDEBUG
    self.mediaDiscoverer.libraryInstance.debugLogging = NO;
#endif
    [discoverer startDiscoverer];
    discoverer.discoveredMedia.delegate = self;

}

- (void)stopDiscovery
{
    VLCMediaDiscoverer *discoverer = self.mediaDiscoverer;
    discoverer.discoveredMedia.delegate = nil;
    [discoverer stopDiscoverer];
    self.mediaDiscoverer = nil;
}

- (NSUInteger)numberOfItems {
    return self.mediaDiscoverer.discoveredMedia.count;
}
- (id<rqdMediaLocalNetworkService>)networkServiceForIndex:(NSUInteger)index {
    VLCMedia *media = [self.mediaDiscoverer.discoveredMedia mediaAtIndex:index];
    if (media)
        return [[rqdMediaLocalNetworkServiceVLCMedia alloc] initWithMediaItem:media serviceName:self.serviceName];
    return nil;
}

#pragma mark - VLCMediaListDelegate
- (void)mediaList:(VLCMediaList *)aMediaList mediaAdded:(VLCMedia *)media atIndex:(NSInteger)index
{
    [self.delegate localNetworkServiceBrowserDidUpdateServices:self];
}
- (void)mediaList:(VLCMediaList *)aMediaList mediaRemovedAtIndex:(NSInteger)index
{
    [self.delegate localNetworkServiceBrowserDidUpdateServices:self];
}

@end
