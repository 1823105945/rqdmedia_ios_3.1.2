/*****************************************************************************
 * rqdMediaLocalServerListViewController.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaLocalServerDiscoveryController.h"

#import "Reachability.h"
#import "rqdMediaLocalNetworkServiceBrowser-Protocol.h"

@interface rqdMediaLocalServerDiscoveryController () <rqdMediaLocalNetworkServiceBrowserDelegate>
{
    NSArray<id<rqdMediaLocalNetworkServiceBrowser>> *_serviceBrowsers;
    Reachability *_reachability;
}

@end

@implementation rqdMediaLocalServerDiscoveryController

- (instancetype)initWithServiceBrowserClasses:(NSArray<Class> *)serviceBrowserClasses
{
    self = [super init];
    if (!self)
        return nil;

    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

    [defaultCenter addObserver:self
                      selector:@selector(stopDiscovery)
                          name:UIApplicationWillResignActiveNotification
                        object:[UIApplication sharedApplication]];

    [defaultCenter addObserver:self
                      selector:@selector(startDiscovery)
                          name:UIApplicationDidBecomeActiveNotification
                        object:[UIApplication sharedApplication]];


    NSMutableArray *serviceBrowsers = [NSMutableArray new];
    for (Class browserClass in serviceBrowserClasses) {
        if ([browserClass conformsToProtocol:@protocol(rqdMediaLocalNetworkServiceBrowser)]) {
            [serviceBrowsers addObject:[[browserClass alloc] init]];
        }
    }
    _serviceBrowsers = [serviceBrowsers copy];

    [_serviceBrowsers enumerateObjectsUsingBlock:^(id<rqdMediaLocalNetworkServiceBrowser>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.delegate = self;
    }];


    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netReachabilityChanged) name:kReachabilityChangedNotification object:nil];

    _reachability = [Reachability reachabilityForLocalWiFi];
    [_reachability startNotifier];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_reachability stopNotifier];
    [self stopDiscovery];
}

- (void)startDiscovery
{
    if (_reachability.currentReachabilityStatus != ReachableViaWiFi) {
        return;
    }

    [_serviceBrowsers makeObjectsPerformSelector:@selector(startDiscovery)];
}

- (void)stopDiscovery
{
    [_serviceBrowsers makeObjectsPerformSelector:@selector(stopDiscovery)];
}

- (BOOL)refreshDiscoveredData
{
    if (_reachability.currentReachabilityStatus != ReachableViaWiFi)
        return NO;

    [self stopDiscovery];
    [self startDiscovery];

    return YES;
}

#pragma mark - Reachability
- (void)netReachabilityChanged
{
    if (_reachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self startDiscovery];
    } else {
        [self stopDiscovery];
    }
}

#pragma mark - data source

- (NSUInteger)numberOfSections {
    return _serviceBrowsers.count;
}

- (NSString *)titleForSection:(NSUInteger)section
{
    id<rqdMediaLocalNetworkServiceBrowser> browser = _serviceBrowsers[section];
    return browser.name;
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section
{
    id<rqdMediaLocalNetworkServiceBrowser> browser = _serviceBrowsers[section];
    return browser.numberOfItems;
}

- (id<rqdMediaLocalNetworkService>)networkServiceForIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger section = indexPath.section;
    NSUInteger row = indexPath.row;

    id<rqdMediaLocalNetworkServiceBrowser> browser = _serviceBrowsers[section];
    return [browser networkServiceForIndex:row];
}

- (BOOL)foundAnythingAtAll
{
    NSUInteger serviceCount = _serviceBrowsers.count;
    BOOL ret = NO;
    for (NSUInteger i = 0; i < serviceCount; i++) {
        ret = [_serviceBrowsers[i] numberOfItems] > 0;
        if (ret)
            break;
    }
    return ret;
}

#pragma mark - rqdMediaLocalNetworkServiceBrowserDelegate
- (void)localNetworkServiceBrowserDidUpdateServices:(id<rqdMediaLocalNetworkServiceBrowser>)serviceBrowser {
    if ([self.delegate respondsToSelector:@selector(discoveryFoundSomethingNew)]) {
        [self.delegate discoveryFoundSomethingNew];
    }
}

@end
