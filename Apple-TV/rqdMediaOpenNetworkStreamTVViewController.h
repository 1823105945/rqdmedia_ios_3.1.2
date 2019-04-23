/*****************************************************************************
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>
#import "rqdMediaDeletionCapableViewController.h"

@interface rqdMediaOpenNetworkStreamTVViewController : rqdMediaDeletionCapableViewController <UITableViewDataSource, UITableViewDelegate>

@property (readwrite, nonatomic, weak) IBOutlet UITextField *playURLField;
@property (readwrite, nonatomic, weak) IBOutlet UITableView *previouslyPlayedStreamsTableView;

@property (readwrite, nonatomic, weak) IBOutlet UILabel *nothingFoundLabel;
@property (readwrite, nonatomic, weak) IBOutlet UIView *nothingFoundView;
@property (readwrite, nonatomic, weak) IBOutlet UIImageView *nothingFoundConeImageView;

- (IBAction)URLEnteredInField:(id)sender;

@end
