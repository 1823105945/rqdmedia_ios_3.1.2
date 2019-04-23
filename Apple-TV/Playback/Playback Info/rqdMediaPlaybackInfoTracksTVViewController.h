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

#import "rqdMediaPlaybackInfoPanelTVViewController.h"

@interface rqdMediaPlaybackInfoTracksTVViewController : rqdMediaPlaybackInfoPanelTVViewController
@property (nonatomic, strong) IBOutlet UICollectionView *audioTrackCollectionView;
@property (nonatomic, strong) IBOutlet UICollectionView *subtitleTrackCollectionView;
@end
