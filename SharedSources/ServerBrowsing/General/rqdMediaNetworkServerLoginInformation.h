/*****************************************************************************
 * rqdMediaNetworkServerLoginInformation.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import "rqdMediaLocalNetworkService-Protocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface rqdMediaNetworkServerLoginInformationField : NSObject <NSCopying, rqdMediaNetworkServerLoginInformationField>
@property (nonatomic, readonly) rqdMediaNetworkServerLoginInformationFieldType type;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *localizedLabel;
@property (nonatomic, copy) NSString *textValue;

- (instancetype)initWithType:(rqdMediaNetworkServerLoginInformationFieldType)type
                  identifier:(NSString *)identifier
                       label:(NSString *)localizedLabel
                   textValue:(nullable NSString *)initialValue NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface rqdMediaNetworkServerLoginInformation : NSObject <NSCopying, rqdMediaNetworkServerLoginInformation>
@property (nonatomic, copy, nullable) NSString *username;
@property (nonatomic, copy, nullable) NSString *password;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, copy) NSNumber *port;
@property (nonatomic, copy) NSString *protocolIdentifier;
@property (nonatomic, copy) NSArray<rqdMediaNetworkServerLoginInformationField *> *additionalFields;

+ (instancetype)newLoginInformationForProtocol:(NSString *)protocolIdentifier;
+ (void)registerTemplateLoginInformation:(rqdMediaNetworkServerLoginInformation *)loginInformation;
@end
NS_ASSUME_NONNULL_END
