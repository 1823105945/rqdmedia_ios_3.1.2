/*****************************************************************************
 * rqdMediaLocalNetworkListViewController
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015-2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@class rqdMediaNetworkListCell;

extern NSString *rqdMediaNetworkListCellIdentifier;

@interface rqdMediaNetworkListViewController : UIViewController

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchController *searchController;

- (IBAction)playAllAction:(id)sender;
- (void)tableView:(UITableView *)tableView willDisplayCell:(rqdMediaNetworkListCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;

@end
