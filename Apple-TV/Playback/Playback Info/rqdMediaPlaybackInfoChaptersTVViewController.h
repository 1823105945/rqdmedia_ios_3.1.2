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

@interface rqdMediaPlaybackInfoChaptersTVViewController : rqdMediaPlaybackInfoPanelTVViewController
@property (nonatomic, weak) IBOutlet UICollectionView *titlesCollectionView;
@property (nonatomic, weak) IBOutlet UICollectionView *chaptersCollectionView;

@end
