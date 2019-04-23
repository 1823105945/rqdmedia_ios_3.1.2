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
@class rqdMediaNetworkServerLoginInformation, rqdMediaNetworkLoginDataSourceSavedLogins;

@protocol rqdMediaNetworkLoginDataSourceSavedLoginsDelegate <NSObject>

- (void)loginsDataSource:(rqdMediaNetworkLoginDataSourceSavedLogins *)dataSource selectedLogin:(rqdMediaNetworkServerLoginInformation *)login;

@end

@interface rqdMediaNetworkLoginDataSourceSavedLogins : NSObject <rqdMediaNetworkLoginDataSourceSection>
@property (nonatomic, weak) id<rqdMediaNetworkLoginDataSourceSavedLoginsDelegate> delegate;
- (BOOL)saveLogin:(rqdMediaNetworkServerLoginInformation *)login error:(NSError **)error;
- (BOOL)deleteItemAtRow:(NSUInteger)row error:(NSError **)error;

@end
NS_ASSUME_NONNULL_END
