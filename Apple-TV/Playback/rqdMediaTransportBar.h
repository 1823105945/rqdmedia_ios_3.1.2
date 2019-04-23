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

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, rqdMediaTransportBarHint) {
    rqdMediaTransportBarHintNone,
    rqdMediaTransportBarHintScanForward,
    rqdMediaTransportBarHintJumpForward10,
    rqdMediaTransportBarHintJumpBackward10,
};

IB_DESIGNABLE @interface rqdMediaTransportBar : UIView
@property (nonatomic) IBInspectable CGFloat bufferStartFraction;
@property (nonatomic) IBInspectable CGFloat bufferEndFraction;
@property (nonatomic) IBInspectable CGFloat playbackFraction;
@property (nonatomic) IBInspectable CGFloat scrubbingFraction;
@property (nonatomic, getter=isScrubbing) IBInspectable BOOL scrubbing;

@property (nonatomic, readonly) UILabel *markerTimeLabel;
@property (nonatomic, readonly) UILabel *remainingTimeLabel;

@property (nonatomic) rqdMediaTransportBarHint hint;
@end

NS_ASSUME_NONNULL_END