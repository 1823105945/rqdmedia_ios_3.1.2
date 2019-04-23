/*****************************************************************************
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface rqdMediaRemoteBrowsingCollectionViewController : UICollectionViewController

@property (readwrite, weak, nonatomic) IBOutlet UIView *nothingFoundView;
@property (readwrite, weak, nonatomic) IBOutlet UILabel *nothingFoundLabel;
@property (readwrite, weak, nonatomic) IBOutlet UIImageView *nothingFoundConeImageView;

@end
