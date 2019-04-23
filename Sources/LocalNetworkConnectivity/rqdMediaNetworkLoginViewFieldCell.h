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

NS_ASSUME_NONNULL_BEGIN

extern NSString * const krqdMediaNetworkLoginViewFieldCellIdentifier;

@protocol rqdMediaNetworkLoginViewFieldCellDelegate;

@interface rqdMediaNetworkLoginViewFieldCell : UITableViewCell
@property (nonatomic, weak) id<rqdMediaNetworkLoginViewFieldCellDelegate> delegate;
@property (nonatomic, retain) UITextField *textField;
@property (nonatomic, nullable, copy) NSString *placeholderString;
@end

@protocol rqdMediaNetworkLoginViewFieldCellDelegate <NSObject>
- (BOOL)loginViewFieldCellShouldReturn:(rqdMediaNetworkLoginViewFieldCell *)cell;
- (void)loginViewFieldCellDidEndEditing:(rqdMediaNetworkLoginViewFieldCell *)cell;
@end

NS_ASSUME_NONNULL_END
