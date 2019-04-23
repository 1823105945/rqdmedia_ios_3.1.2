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

typedef NS_ENUM(NSInteger, rqdMediaSiriRemoteTouchLocation){
    rqdMediaSiriRemoteTouchLocationUnknown,
    rqdMediaSiriRemoteTouchLocationLeft,
    rqdMediaSiriRemoteTouchLocationRight,
    rqdMediaSiriRemoteTouchLocationUp,
    rqdMediaSiriRemoteTouchLocationDown
};

@interface rqdMediaSiriRemoteGestureRecognizer : UIGestureRecognizer
@property (nonatomic) NSTimeInterval minLongPressDuration; // default = 0.5
@property (nonatomic, readonly, getter=isLongPress) BOOL longPress;
@property (nonatomic, readonly, getter=isClick) BOOL click;
@property (nonatomic, readonly) rqdMediaSiriRemoteTouchLocation touchLocation;

@end

