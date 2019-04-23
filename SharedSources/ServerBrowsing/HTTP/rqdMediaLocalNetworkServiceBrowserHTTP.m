/*****************************************************************************
 * rqdMediaLocalNetworkServiceBrowserHTTP.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaLocalNetworkServiceBrowserHTTP.h"
#import "rqdMediaSharedLibraryParser.h"
#import "rqdMediaHTTPUploaderController.h"
#import "rqdMediaNetworkServerBrowserSharedLibrary.h"

@interface rqdMediaLocalNetworkServiceBrowserHTTP()
@property (nonatomic) rqdMediaSharedLibraryParser *httpParser;
@end
@implementation rqdMediaLocalNetworkServiceBrowserHTTP
- (instancetype)init {
    return [super initWithName:NSLocalizedString(@"SHARED_rqdMedia_IOS_LIBRARY", nil)
                   serviceType:@"_http._tcp."
                        domain:@""];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (rqdMediaSharedLibraryParser *)httpParser {
    if (!_httpParser) {
        _httpParser = [[rqdMediaSharedLibraryParser alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sharedLibraryFound:)
                                                     name:rqdMediaSharedLibraryParserDeterminedNetserviceAsrqdMediaInstance
                                                   object:_httpParser];
    }
    return _httpParser;
}
- (void)netServiceDidResolveAddress:(NSNetService *)sender {
#if !TARGET_OS_TV
    NSString *ownHostname = [[rqdMediaHTTPUploaderController sharedInstance] hostname];
    if ([[sender hostName] rangeOfString:ownHostname].location != NSNotFound) {
        return;
    }
#endif
    [self.httpParser checkNetserviceForrqdMediaService:sender];
}

- (void)sharedLibraryFound:(NSNotification *)aNotification {
    NSNetService *netService = [aNotification.userInfo objectForKey:@"aNetService"];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self addResolvedLocalNetworkService:[self localServiceForNetService:netService]];
    }];
}

- (rqdMediaLocalNetworkServiceNetService *)localServiceForNetService:(NSNetService *)netService {
    return [[rqdMediaLocalNetworkServiceHTTP alloc] initWithNetService:netService serviceName:self.name];
}
@end



@implementation rqdMediaLocalNetworkServiceHTTP

- (UIImage *)icon {
    return [UIImage imageNamed:@"rqdmedia-sharing"];
}

- (id<rqdMediaNetworkServerBrowser>)serverBrowser {

    NSNetService *service = self.netService;
    if (service.hostName == nil || service.port == 0) {
        return nil;
    }

    NSString *name = service.name;
    NSString *hostName = service.hostName;
    NSUInteger portNum = service.port;
    rqdMediaNetworkServerBrowserSharedLibrary *serverBrowser = [[rqdMediaNetworkServerBrowserSharedLibrary alloc] initWithName:name host:hostName portNumber:portNum];
    return serverBrowser;
}

@end