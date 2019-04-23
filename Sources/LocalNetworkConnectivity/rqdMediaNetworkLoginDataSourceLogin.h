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

#import <UIKit/UIKit.h>
#import "rqdMediaNetworkServerLoginInformation.h"
#import "rqdMediaNetworkLoginDataSourceSection.h"

NS_ASSUME_NONNULL_BEGIN

@protocol rqdMediaNetworkLoginDataSourceLoginDelegate;

@interface rqdMediaNetworkLoginDataSourceLogin : NSObject <rqdMediaNetworkLoginDataSourceSection>
@property (nonatomic, weak) id <rqdMediaNetworkLoginDataSourceLoginDelegate> delegate;
@property (nonatomic, nullable) rqdMediaNetworkServerLoginInformation *loginInformation;
@end

@protocol rqdMediaNetworkLoginDataSourceLoginDelegate <NSObject>
- (void)saveLoginDataSource:(rqdMediaNetworkLoginDataSourceLogin *)dataSource;
- (void)connectLoginDataSource:(rqdMediaNetworkLoginDataSourceLogin *)dataSource;
@end

NS_ASSUME_NONNULL_END
