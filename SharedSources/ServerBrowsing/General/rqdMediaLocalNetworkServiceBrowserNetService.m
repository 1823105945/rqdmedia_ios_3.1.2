/*****************************************************************************
 * rqdMediaLocalNetworkServiceBrowserNetService.m
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

@interface NSMutableArray(rqdMediaLocalNetworkServiceNetService)
-(NSUInteger)rqdmedia_indexOfServiceWithNetService:(NSNetService*)netService;
-(void)rqdmedia_removeServiceWithNetService:(NSNetService*)netService;

@end
@implementation NSMutableArray (rqdMediaLocalNetworkServiceNetService)

- (NSUInteger)rqdmedia_indexOfServiceWithNetService:(NSNetService *)netService {
    NSUInteger index = [self indexOfObjectPassingTest:^BOOL(rqdMediaLocalNetworkServiceNetService *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj respondsToSelector:@selector(netService)]) return false;
        BOOL equal = [obj.netService isEqual:netService];
        if (equal) {
            *stop = YES;
        }
        return equal;
    }];
    return index;
}
-(void)rqdmedia_removeServiceWithNetService:(NSNetService *)netService {
    NSUInteger index = [self rqdmedia_indexOfServiceWithNetService:netService];
    if (index != NSNotFound) {
        [self removeObjectAtIndex:index];
    }
}
@end

#pragma mark - NetService based implementation

@implementation rqdMediaLocalNetworkServiceBrowserNetService
@synthesize name = _name;

- (instancetype)initWithName:(NSString *)name serviceType:(NSString *)serviceType domain:(NSString *)domain
{
    self = [super init];
    if (self) {
        _name = name;
        _serviceType = serviceType;
        _domain = domain;
        _netServiceBrowser = [[NSNetServiceBrowser alloc] init];
        _netServiceBrowser.delegate = self;
        _rawNetServices = [[NSMutableArray alloc] init];
        _resolvedLocalNetworkServices = [[NSMutableArray alloc] init];
    }
    return self;
}
- (instancetype)init {
    return [self initWithName:@"" serviceType:@"" domain:@""];
}

- (NSUInteger)numberOfItems {
    return self.resolvedLocalNetworkServices.count;
}
- (void)startDiscovery {
    if (self.isDiscovering) {
        return;
    }
    _discovering = YES;
    [self.netServiceBrowser searchForServicesOfType:self.serviceType inDomain:self.domain];
}
- (void)stopDiscovery {
    [self.netServiceBrowser stop];
    _discovering = NO;
}
- (id<rqdMediaLocalNetworkService>)networkServiceForIndex:(NSUInteger)index {
    if (index < _resolvedLocalNetworkServices.count)
        return self.resolvedLocalNetworkServices[index];
    return nil;
}

#pragma mark - NSNetServiceBrowserDelegate
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing {
    APLog(@"found bonjour service: %@ (%@)", service.name, service.type);
    [self.rawNetServices addObject:service];
    service.delegate = self;
    [service resolveWithTimeout:5.];
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(nonnull NSNetService *)service moreComing:(BOOL)moreComing {
    APLog(@"bonjour service disappeared: %@ (%i)", service.name, moreComing);
    [self.rawNetServices removeObject:service];
    [self.resolvedLocalNetworkServices rqdmedia_removeServiceWithNetService:service];

    if (!moreComing) {
        [self.delegate localNetworkServiceBrowserDidUpdateServices:self];
    }
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary<NSString *,NSNumber *> *)errorDict {
    APLog(@"bonjour service did not search: %@ %@", browser, errorDict);
}


#pragma mark - NSNetServiceDelegate
- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    rqdMediaLocalNetworkServiceNetService *localNetworkService = [self localServiceForNetService:sender];
    [self addResolvedLocalNetworkService:localNetworkService];
}
- (rqdMediaLocalNetworkServiceNetService *)localServiceForNetService:(NSNetService *)netService {
    return [[rqdMediaLocalNetworkServiceNetService alloc] initWithNetService:netService serviceName:self.name];
}

#pragma mark -
- (void)addResolvedLocalNetworkService:(rqdMediaLocalNetworkServiceNetService *)localNetworkService {
    if ([self.resolvedLocalNetworkServices rqdmedia_indexOfServiceWithNetService:localNetworkService.netService] != NSNotFound) {
        return;
    }
    [self.resolvedLocalNetworkServices addObject:localNetworkService];
    [self.delegate localNetworkServiceBrowserDidUpdateServices:self];
}
@end
