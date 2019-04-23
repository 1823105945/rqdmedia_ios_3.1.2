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

@class rqdMediaPlaybackInfoTVViewController;
@interface rqdMediaPlaybackInfoTabBarTVTransitioningAnimator : NSObject <UIViewControllerAnimatedTransitioning>
@property (nonatomic) rqdMediaPlaybackInfoTVViewController *infoContainerViewController;
@end

@interface rqdMediaPlaybackInfoTVTransitioningAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@end

