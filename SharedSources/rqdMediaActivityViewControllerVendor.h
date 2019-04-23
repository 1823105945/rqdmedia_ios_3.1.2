/*****************************************************************************
 * rqdMediaActivityViewControllerVendor.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@interface rqdMediaActivityViewControllerVendor : NSObject

+ (UIActivityViewController *)activityViewControllerForFiles:(NSArray *)files presentingButton:(UIBarButtonItem *)button presentingViewController:(UIViewController *)controller;

@end
