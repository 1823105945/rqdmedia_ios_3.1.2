/*****************************************************************************
 * rqdMediaLocalNetworkServiceBrowserDSM.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaLocalNetworkServiceBrowserDSM.h"
#import "rqdMediaNetworkServerLoginInformation.h"

@interface rqdMediaLocalNetworkServiceDSM ()
+ (void)registerLoginInformation;
@end

@implementation rqdMediaLocalNetworkServiceBrowserDSM

- (instancetype)init {
#if TARGET_OS_TV
    NSString *name = NSLocalizedString(@"SMB_CIFS_FILE_SERVERS_SHORT", nil);
#else
    NSString *name = NSLocalizedString(@"SMB_CIFS_FILE_SERVERS", nil);
#endif

    return [super initWithName:name
            serviceServiceName:@"dsm"];
}
- (id<rqdMediaLocalNetworkService>)networkServiceForIndex:(NSUInteger)index {
    VLCMedia *media = [self.mediaDiscoverer.discoveredMedia mediaAtIndex:index];
    if (media)
        return [[rqdMediaLocalNetworkServiceDSM alloc] initWithMediaItem:media serviceName:self.name];
    return nil;
}

+ (void)initialize
{
    [super initialize];
    [rqdMediaLocalNetworkServiceDSM registerLoginInformation];
}

@end


NSString *const rqdMediaNetworkServerProtocolIdentifierSMB = @"smb";
static NSString *const rqdMediaLocalNetworkServiceDSMWorkgroupIdentifier = @"rqdMediaLocalNetworkServiceDSMWorkgroup";

@implementation rqdMediaLocalNetworkServiceDSM


+ (void)registerLoginInformation
{
    rqdMediaNetworkServerLoginInformation *login = [[rqdMediaNetworkServerLoginInformation alloc] init];
    login.protocolIdentifier = rqdMediaNetworkServerProtocolIdentifierSMB;
    rqdMediaNetworkServerLoginInformationField *workgroupField = [[rqdMediaNetworkServerLoginInformationField alloc] initWithType:rqdMediaNetworkServerLoginInformationFieldTypeText
                                                                                                             identifier:rqdMediaLocalNetworkServiceDSMWorkgroupIdentifier
                                                                                                                  label:NSLocalizedString(@"DSM_WORKGROUP", nil)
                                                                                                              textValue:@"WORKGROUP"];
    login.additionalFields = @[workgroupField];


    [rqdMediaNetworkServerLoginInformation registerTemplateLoginInformation:login];
}

- (UIImage *)icon {
    return [UIImage imageNamed:@"serverIcon"];
}
- (rqdMediaNetworkServerLoginInformation *)loginInformation {

    VLCMedia *media = self.mediaItem;
    if (media.mediaType != VLCMediaTypeDirectory)
        return nil;

    rqdMediaNetworkServerLoginInformation *login = [rqdMediaNetworkServerLoginInformation newLoginInformationForProtocol:rqdMediaNetworkServerProtocolIdentifierSMB];
    login.address = self.mediaItem.url.host;
    return login;
}

@end


@implementation rqdMediaNetworkServerBrowserVLCMedia (SMB)

+ (instancetype)SMBNetworkServerBrowserWithLogin:(rqdMediaNetworkServerLoginInformation *)login
{
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = @"smb";
    components.host = login.address;
    components.port = login.port;
    NSURL *url = components.URL;

    __block NSString *workgroup = nil;
    [login.additionalFields enumerateObjectsUsingBlock:^(rqdMediaNetworkServerLoginInformationField * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.identifier isEqualToString:rqdMediaLocalNetworkServiceDSMWorkgroupIdentifier])
        {
            workgroup = obj.textValue;
        }
    }];

    return [self SMBNetworkServerBrowserWithURL:url
                                       username:login.username
                                       password:login.password
                                      workgroup:workgroup];
}

+ (instancetype)SMBNetworkServerBrowserWithURL:(NSURL *)url username:(NSString *)username password:(NSString *)password workgroup:(NSString *)workgroup
{
	VLCMedia *media = [VLCMedia mediaWithURL:url];
	NSDictionary *mediaOptions = @{@"smb-user" : username ?: @"",
								   @"smb-pwd" : password ?: @"",
								   @"smb-domain" : workgroup?: @"WORKGROUP"};
	[media addOptions:mediaOptions];
	return [[self alloc] initWithMedia:media options:mediaOptions];
}
@end