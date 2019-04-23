/*****************************************************************************
 * rqdMediaAppDelegate.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Jean-Romain Prévost <jr # 3on.fr>
 *          Carola Nitz <nitz.carola # googlemail.com>
 *          Tamas Timar <ttimar.rqdmedia # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaMenuTableViewController.h"
#import "rqdMediaDownloadViewController.h"
#import "rqdMediaWatchCommunication.h"
#import <AppAuth/AppAuth.h>

@class VLCLibraryViewController;

extern NSString *const rqdMediaDropboxSessionWasAuthorized;

@interface rqdMediaAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, readonly) VLCLibraryViewController *libraryViewController;

@property (nonatomic, readonly) rqdMediaWatchCommunication *watchCommunication;

@property (nonatomic, strong) UIWindow *window;

@property (atomic, strong) id<OIDAuthorizationFlowSession> currentGoogleAuthorizationFlow;

@end
