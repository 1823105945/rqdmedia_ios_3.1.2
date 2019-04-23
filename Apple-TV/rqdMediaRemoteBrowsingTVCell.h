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
#import "rqdMediaServerBrowsingController.h"
#import "rqdMediaNetworkImageView.h"

extern NSString *const rqdMediaRemoteBrowsingTVCellIdentifier;

@interface rqdMediaRemoteBrowsingTVCell : UICollectionViewCell <rqdMediaRemoteBrowsingCell>

@property (nonatomic, weak) IBOutlet rqdMediaNetworkImageView *thumbnailImageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;

@property (nonatomic) BOOL downloadArtwork;

@end
