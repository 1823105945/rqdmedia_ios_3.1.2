/*****************************************************************************
 * rqdMediaLocalNetworkServiceBrowserFTP.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaLocalNetworkServiceBrowserFTP.h"
#import "rqdMediaNetworkServerLoginInformation.h"

@implementation rqdMediaLocalNetworkServiceBrowserFTP
- (instancetype)init {
#if TARGET_OS_TV
    NSString *name = NSLocalizedString(@"FTP_SHORT",nil);
#else
    NSString *name = NSLocalizedString(@"FTP_LONG",nil);
#endif
    return [super initWithName:name
                   serviceType:@"_ftp._tcp."
                        domain:@""];
}
- (rqdMediaLocalNetworkServiceNetService *)localServiceForNetService:(NSNetService *)netService {
    return [[rqdMediaLocalNetworkServiceFTP alloc] initWithNetService:netService serviceName:self.self.name];
}
@end


NSString *const rqdMediaNetworkServerProtocolIdentifierFTP = @"ftp";

@implementation rqdMediaLocalNetworkServiceFTP
- (UIImage *)icon {
    return [UIImage imageNamed:@"serverIcon"];
}

- (nullable id<rqdMediaNetworkServerLoginInformation>)loginInformation
{
    rqdMediaNetworkServerLoginInformation *login = [[rqdMediaNetworkServerLoginInformation alloc] init];
    login.address = self.netService.hostName;
    login.port = [NSNumber numberWithInteger:self.netService.port];
    login.protocolIdentifier = rqdMediaNetworkServerProtocolIdentifierFTP;

    return login;
}
@end
