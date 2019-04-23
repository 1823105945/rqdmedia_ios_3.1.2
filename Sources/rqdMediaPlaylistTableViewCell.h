/*****************************************************************************
 * rqdMediaPlaylistTableViewCell.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/
#import <UIKit/UIKit.h>

static NSString *kPlaylistCellIdentifier = @"PlaylistCell";

@class rqdMediaLinearProgressIndicator;
@interface rqdMediaPlaylistTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *metaDataLabel;
@property (nonatomic, strong) IBOutlet UIImageView *thumbnailView;
@property (nonatomic, strong) IBOutlet rqdMediaLinearProgressIndicator *progressIndicator;
@property (nonatomic, strong) IBOutlet UIView *mediaIsUnreadView;
@property (nonatomic, strong) IBOutlet UIImageView *folderIconView;

@property (readonly) BOOL isExpanded;

@property (nonatomic, strong) NSManagedObject *mediaObject;

+ (CGFloat)heightOfCell;

- (void)collapsWithAnimation:(BOOL)animate;

@end
