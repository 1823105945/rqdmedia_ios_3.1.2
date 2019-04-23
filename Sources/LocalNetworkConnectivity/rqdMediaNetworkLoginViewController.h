/*****************************************************************************
 * rqdMediaNetworkLoginViewController.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *          Vincent L. Cone <vincent.l.cone # tuta.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@class rqdMediaNetworkServerLoginInformation, rqdMediaNetworkLoginViewController;

NS_ASSUME_NONNULL_BEGIN
@protocol rqdMediaNetworkLoginViewControllerDelegate <NSObject>
@required
- (void)loginWithLoginViewController:(rqdMediaNetworkLoginViewController *)loginViewController loginInfo:(rqdMediaNetworkServerLoginInformation *)loginInformation;
@end

@interface rqdMediaNetworkLoginViewController : UIViewController
@property (nonatomic) rqdMediaNetworkServerLoginInformation *loginInformation;
@property (nonatomic, weak, nullable) id<rqdMediaNetworkLoginViewControllerDelegate> delegate;

@end
NS_ASSUME_NONNULL_END
