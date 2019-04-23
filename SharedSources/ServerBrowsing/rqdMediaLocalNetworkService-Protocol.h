/*****************************************************************************
 * rqdMediaLocalNetworkService-Protocol.h
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
#import "rqdMediaNetworkServerBrowser-Protocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, rqdMediaNetworkServerLoginInformationFieldType) {
    rqdMediaNetworkServerLoginInformationFieldTypeText,
    rqdMediaNetworkServerLoginInformationFieldTypeNumber
};

@protocol rqdMediaNetworkServerLoginInformationField <NSObject>
@property (nonatomic, readonly) rqdMediaNetworkServerLoginInformationFieldType type;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *localizedLabel;
@property (nonatomic, copy) NSString *textValue;
@end

@protocol rqdMediaNetworkServerLoginInformation <NSObject>
@property (nonatomic, copy, nullable) NSString *username;
@property (nonatomic, copy, nullable) NSString *password;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, copy) NSNumber *port;
@property (nonatomic, copy) NSString *protocolIdentifier;
@property (nonatomic, copy) NSArray< id<rqdMediaNetworkServerLoginInformationField>> *additionalFields;
@end

@protocol rqdMediaLocalNetworkService <NSObject>

@required
@property (nonatomic, readonly, nullable) UIImage *icon;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *serviceName;

@optional
- (nullable id<rqdMediaNetworkServerBrowser>)serverBrowser;
- (NSURL *)directPlaybackURL;
- (nullable id<rqdMediaNetworkServerLoginInformation>)loginInformation;

@end

NS_ASSUME_NONNULL_END
