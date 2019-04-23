/*****************************************************************************
 * BasicUPnPDevice+rqdMedia.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Marc Etcheverry <marc # taplightsoftware com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "BasicUPnPDevice.h"

/// Extension to detect HDHomeRun devices
@interface BasicUPnPDevice (rqdMedia)

- (BOOL)rqdMedia_isHDHomeRunMediaServer;

@end
