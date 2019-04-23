/*****************************************************************************
 * rqdMediaStreamingHistoryCell.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Adam Viaud <mcnight # mcnight.fr>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaStreamingHistoryCell.h"

@implementation rqdMediaStreamingHistoryCell

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return (action == @selector(copy:) || action == @selector(renameStream:)) || [super canPerformAction:action withSender:sender];
}

- (void)customizeAppearance {
    UIColor *blackColor = [UIColor blackColor];
    self.textLabel.textColor = [UIColor whiteColor];
    self.textLabel.highlightedTextColor = blackColor;
    self.detailTextLabel.textColor = [UIColor rqdMediaLightTextColor];
    self.detailTextLabel.highlightedTextColor = blackColor;
}

- (void)renameStream:(id)sender {
    [self.delegate renameStreamFromCell:self];
}

@end
