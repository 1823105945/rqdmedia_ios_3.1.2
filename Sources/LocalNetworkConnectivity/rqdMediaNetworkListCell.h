/*****************************************************************************
 * rqdMediaNetworkListCell.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>
#import "rqdMediaNetworkImageView.h"
#import "rqdMediaServerBrowsingController.h"

@class rqdMediaStatusLabel;

@interface rqdMediaNetworkListCell : UITableViewCell

@property (nonatomic, weak) id delegate;

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *folderTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet rqdMediaNetworkImageView *thumbnailView;
@property (nonatomic, strong) IBOutlet UIButton *downloadButton;
@property (nonatomic, strong) IBOutlet rqdMediaStatusLabel *statusLabel;

@property (nonatomic, readwrite) BOOL isDirectory;

/// When there is no subtitle content, you might want to enable this
@property (nonatomic, getter = isTitleLabelCentered) BOOL titleLabelCentered;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *subtitle;
@property (nonatomic, retain) UIImage *icon;
@property (nonatomic, retain) NSURL *iconURL;
@property (nonatomic, readwrite) BOOL isDownloadable;

+ (rqdMediaNetworkListCell *)cellWithReuseIdentifier:(NSString *)ident;
+ (CGFloat)heightOfCell;

- (IBAction)triggerDownload:(id)sender;

@end

@protocol rqdMediaNetworkListCellDelegate <NSObject>

- (void)triggerDownloadForCell:(rqdMediaNetworkListCell *)cell;

@end


@interface rqdMediaNetworkListCell (CellConfigurator) <rqdMediaRemoteBrowsingCell>

@end