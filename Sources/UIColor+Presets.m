/*****************************************************************************
 * UIColor+Presets.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "UIColor+Presets.h"

@implementation UIColor (Presets)

+ (UIColor *)rqdMediaDarkBackgroundColor
{
    return [UIColor colorWithWhite:.122 alpha:1.];
}

+ (UIColor *)rqdMediaTransparentDarkBackgroundColor
{
    return [UIColor colorWithWhite:.122 alpha:0.75];
}

+ (UIColor *)rqdMediaLightTextColor
{
    return [UIColor colorWithWhite:.72 alpha:1.];
}

+ (UIColor *)rqdMediaDarkFadedTextColor {
    return [UIColor colorWithRed:0.33 green:0.33 blue:0.33 alpha:1.0];
}

+ (UIColor *)rqdMediaDarkTextColor
{
    return [UIColor colorWithWhite:.28 alpha:1.];
}

+ (UIColor *)rqdMediaDarkTextShadowColor
{
    return [UIColor colorWithWhite:0. alpha:.25f];
}

+ (UIColor *)rqdMediaMenuBackgroundColor
{
    return [UIColor colorWithWhite:.17f alpha:1.];
}

+ (UIColor *)rqdMediaOrangeTintColor
{
    return [UIColor colorWithRed:1.0f green:(132.0f/255.0f) blue:0.0f alpha:1.f];
}

@end
