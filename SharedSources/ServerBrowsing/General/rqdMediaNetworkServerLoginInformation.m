/*****************************************************************************
 * rqdMediaNetworkServerLoginInformation.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaNetworkServerLoginInformation.h"

@implementation rqdMediaNetworkServerLoginInformationField

- (instancetype)initWithType:(rqdMediaNetworkServerLoginInformationFieldType)type identifier:(NSString *)identifier label:(NSString *)localizedLabel textValue:(NSString *)initialValue
{
    self = [super init];
    if (self) {
        _type = type;
        _identifier = [identifier copy];
        _localizedLabel = [localizedLabel copy];
        _textValue = [initialValue copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithType:self.type identifier:self.identifier label:self.localizedLabel textValue:self.textValue];
}

@end

@implementation rqdMediaNetworkServerLoginInformation

- (id)copyWithZone:(NSZone *)zone
{
    rqdMediaNetworkServerLoginInformation *other = [[[self class] allocWithZone:zone] init];
    other.username = self.username;
    other.password = self.password;
    other.address = self.address;
    other.port = self.port;
    other.protocolIdentifier = self.protocolIdentifier;
    other.additionalFields = [[NSMutableArray alloc] initWithArray:self.additionalFields copyItems:YES];
    return other;
}



static NSMutableDictionary<NSString *, rqdMediaNetworkServerLoginInformation *> *rqdMediaNetworkServerLoginInformationRegistry = nil;
+ (void)initialize
{
    [super initialize];
    rqdMediaNetworkServerLoginInformationRegistry = [[NSMutableDictionary alloc] init];
}

+ (void)registerTemplateLoginInformation:(rqdMediaNetworkServerLoginInformation *)loginInformation
{
    rqdMediaNetworkServerLoginInformationRegistry[loginInformation.protocolIdentifier] = [loginInformation copy];
}

+ (instancetype)newLoginInformationForProtocol:(NSString *)protocolIdentifier
{
    rqdMediaNetworkServerLoginInformation *loginInformation  = [rqdMediaNetworkServerLoginInformationRegistry[protocolIdentifier] copy];
    if (!loginInformation) {
        loginInformation = [[rqdMediaNetworkServerLoginInformation alloc] init];
        loginInformation.protocolIdentifier = protocolIdentifier;
    }
    return loginInformation;
}

@end
