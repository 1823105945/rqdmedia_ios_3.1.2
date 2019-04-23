/*****************************************************************************
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Vincent L. Cone <vincent.l.cone # tuta.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaNetworkServerLoginInformation+Keychain.h"
#import <XKKeychain/XKKeychainGenericPasswordItem.h>

@implementation rqdMediaNetworkServerLoginInformation (Keychain)


+ (instancetype)loginInformationWithKeychainIdentifier:(NSString *)keychainIdentifier
{
    NSURLComponents *components = [NSURLComponents componentsWithString:keychainIdentifier];

    rqdMediaNetworkServerLoginInformation *login = [rqdMediaNetworkServerLoginInformation newLoginInformationForProtocol:components.scheme];
    login.address = components.host;
    login.port = components.port;
    return login;
}

- (NSString *)keychainServiceIdentifier
{
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = self.protocolIdentifier;
    components.host = self.address;
    components.port = self.port;
    NSString *serviceIdentifier = components.URL.absoluteString;
    return serviceIdentifier;
}

- (BOOL)loadLoginInformationFromKeychainWithError:(NSError *__autoreleasing _Nullable *)error
{
    NSError *localError = nil;
    XKKeychainGenericPasswordItem *keychainItem = [XKKeychainGenericPasswordItem itemsForService:self.keychainServiceIdentifier error:&localError].firstObject;
    if (localError) {
        if (error) {
            *error = localError;
        }
        return NO;
    }
    if (!keychainItem) {
        return YES;
    }

    self.username = keychainItem.account;
    self.password = keychainItem.secret.stringValue;

    NSDictionary *genericAttributes = keychainItem.generic.dictionaryValue;
    for (rqdMediaNetworkServerLoginInformationField *field in self.additionalFields) {
        id value = genericAttributes[field.identifier];
        if ([value isKindOfClass:[NSString class]]) {
            field.textValue = value;
        }
    }

    return YES;
}

- (BOOL)saveLoginInformationToKeychainWithError:(NSError *__autoreleasing  _Nullable *)error
{
    XKKeychainGenericPasswordItem *keychainItem = [XKKeychainGenericPasswordItem itemForService:self.keychainServiceIdentifier account:self.username error:nil];
    if (!keychainItem) {
        keychainItem = [[XKKeychainGenericPasswordItem alloc] init];
        keychainItem.service = self.keychainServiceIdentifier;
        keychainItem.account = self.username;
    }

    keychainItem.secret.stringValue = self.password;

    NSArray<rqdMediaNetworkServerLoginInformationField *> *fields = self.additionalFields;
    NSUInteger fieldsCount = fields.count;
    if (fieldsCount) {
        NSMutableDictionary *genericAttributes = [NSMutableDictionary dictionaryWithCapacity:fieldsCount];
        for (rqdMediaNetworkServerLoginInformationField *field in fields) {
            NSString *textValue = field.textValue;
            if (textValue) {
                genericAttributes[field.identifier] = textValue;
            }
        }
        keychainItem.generic.dictionaryValue = genericAttributes;
    }
    return [keychainItem saveWithError:error];
}

- (BOOL)deleteFromKeychainWithError:(NSError *__autoreleasing  _Nullable *)error
{
    XKKeychainGenericPasswordItem *keychainItem = [[XKKeychainGenericPasswordItem alloc] init];
    keychainItem.service = self.keychainServiceIdentifier;
    keychainItem.account = self.username;

    return [keychainItem deleteWithError:error];
}

@end
