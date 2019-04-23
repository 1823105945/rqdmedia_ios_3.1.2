/*****************************************************************************
 * rqdMediaActivityManager.h
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

@interface rqdMediaActivityManager : NSObject

+ (instancetype)defaultManager;

- (void)activateIdleTimer;
- (void)disableIdleTimer;

- (void)networkActivityStarted;
- (BOOL)haveNetworkActivity;
- (void)networkActivityStopped;

@end
