/*****************************************************************************
 * rqdMediaSlider.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "OBSlider.h"

@interface rqdMediaOBSlider : OBSlider

@end

@interface rqdMediaSlider : UISlider

@end

@interface rqdMediaResettingSlider : rqdMediaSlider
@property (nonatomic) IBInspectable float defaultValue;
@property (nonatomic) IBInspectable BOOL resetOnDoubleTap;
@end