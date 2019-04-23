/*****************************************************************************
 * rqdMediaProgressView.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface rqdMediaProgressView : UIView

@property(nonatomic) UIProgressView *progressBar;
@property(nonatomic) UILabel *progressLabel;

- (void)updateTime:(NSString *)time;

@end
