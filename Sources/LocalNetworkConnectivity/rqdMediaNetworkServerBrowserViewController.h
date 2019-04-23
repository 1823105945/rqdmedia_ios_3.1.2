/*****************************************************************************
 * rqdMediaNetworkServerBrowserViewController.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaNetworkListViewController.h"
#import "rqdMediaNetworkServerBrowser-Protocol.h"

@interface rqdMediaNetworkServerBrowserViewController : rqdMediaNetworkListViewController

- (instancetype)initWithServerBrowser:(id<rqdMediaNetworkServerBrowser>)browser;
@end
