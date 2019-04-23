/*****************************************************************************
 * rqdMediaPlaybackController+MediaLibrary.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackController.h"
@class NSManagedObject;
@interface rqdMediaPlaybackController (MediaLibrary)
- (void)playMediaLibraryObject:(NSManagedObject *)mediaObject;
- (void)openMediaLibraryObject:(NSManagedObject *)mediaObject;
- (void)configureMediaListWithFiles:(NSArray *)files indexToPlay:(int)index;
@end
