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
@interface rqdMediaNetworkLoginDataSource : NSObject <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, copy) NSArray<id<rqdMediaNetworkLoginDataSourceSection>> *dataSources;

- (void)configureWithTableView:(UITableView *)tableView;
@end

NS_ASSUME_NONNULL_END