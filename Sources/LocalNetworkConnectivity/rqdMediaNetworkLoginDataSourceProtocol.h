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

#import <Foundation/Foundation.h>
#import "rqdMediaNetworkLoginDataSourceSection.h"

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, rqdMediaServerProtocol) {
    rqdMediaServerProtocolSMB,
    rqdMediaServerProtocolFTP,
    rqdMediaServerProtocolPLEX,
    rqdMediaServerProtocolUndefined,
};
@class rqdMediaNetworkLoginDataSourceProtocol;
@protocol rqdMediaNetworkLoginDataSourceProtocolDelegate <NSObject>
- (void)protocolDidChange:(rqdMediaNetworkLoginDataSourceProtocol *)protocolSection;
@end

@interface rqdMediaNetworkLoginDataSourceProtocol : NSObject <rqdMediaNetworkLoginDataSourceSection>
@property (nonatomic) rqdMediaServerProtocol protocol;
@property (nonatomic, weak) id<rqdMediaNetworkLoginDataSourceProtocolDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
