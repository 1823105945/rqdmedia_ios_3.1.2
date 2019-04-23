/*****************************************************************************
 * UIDevice+rqdMedia.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface UIDevice (rqdMedia)

@property (readonly) NSNumber *rqdMediaFreeDiskSpace;
@property (readonly) BOOL rqdMediaHasExternalDisplay;
@property (readonly) BOOL isiPhoneX;
@end
