/*****************************************************************************
 * rqdMediaStreamingHistoryCell.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Adam Viaud <mcnight # mcnight.fr>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@protocol rqdMediaStreamingHistoryCellMenuItemProtocol
- (void)renameStreamFromCell:(UITableViewCell *)cell;
@end

@interface rqdMediaStreamingHistoryCell : UITableViewCell

@property (weak, nonatomic) id<rqdMediaStreamingHistoryCellMenuItemProtocol> delegate;

- (void)customizeAppearance;

@end
