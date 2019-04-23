/*****************************************************************************
 * rqdMediaPlaylistCollectionViewCell.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Tamas Timar <ttimar.rqdmedia # gmail.com>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>
#import "rqdMediaLinearProgressIndicator.h"

@interface rqdMediaPlaylistCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *thumbnailView;
@property (nonatomic, strong) IBOutlet rqdMediaLinearProgressIndicator *progressView;
@property (nonatomic, strong) IBOutlet UIView *mediaIsUnreadView;
@property (nonatomic, strong) IBOutlet UIImageView *isSelectedView;
@property (nonatomic, strong) IBOutlet UIImageView *folderIconView;
@property (nonatomic, strong) IBOutlet UILabel *metaDataLabel;

@property (nonatomic, retain) NSManagedObject *mediaObject;

@property (nonatomic, weak) UICollectionView *collectionView;
@property (readonly) BOOL showsMetaData;

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
- (void)selectionUpdate;
- (void)shake:(BOOL)shake;
- (void)showMetadata:(BOOL)showMeta;

@end
