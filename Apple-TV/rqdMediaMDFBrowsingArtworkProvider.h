/*****************************************************************************
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

#import "rqdMediaServerBrowsingController.h"

@interface rqdMediaMDFBrowsingArtworkProvider : NSObject

@property (readwrite, weak) id<rqdMediaRemoteBrowsingCell> artworkReceiver;
@property (readwrite, nonatomic) BOOL searchForAudioMetadata;

- (void)reset;
- (void)searchForArtworkForVideoRelatedString:(NSString *)string;

@end
