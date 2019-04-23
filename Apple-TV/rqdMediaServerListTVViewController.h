/*****************************************************************************
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>
#import "rqdMediaRemoteBrowsingCollectionViewController.h"
#import "rqdMediaLocalServerDiscoveryController.h"

@interface rqdMediaServerListTVViewController : rqdMediaRemoteBrowsingCollectionViewController <rqdMediaLocalServerDiscoveryControllerDelegate>

@property (nonatomic) rqdMediaLocalServerDiscoveryController *discoveryController;

@end
