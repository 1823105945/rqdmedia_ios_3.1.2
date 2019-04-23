/*****************************************************************************
 * rqdMediaSettingsController.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaSettingsController.h"
#import "VLCLibraryViewController.h"
#import "IASKSettingsReader.h"
#import "PAPasscodeViewController.h"
#import "rqdMediaAppDelegate.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "rqdMedia_iOS-Swift.h"

@interface rqdMediaSettingsController ()<PAPasscodeViewControllerDelegate, IASKSettingsDelegate>

@end

@implementation rqdMediaSettingsController

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingDidChange:) name:kIASKAppSettingChanged object:nil];
    }

    return self;
}

- (void)viewDidLoad
{
//    self.navigationItem.leftBarButtonItem = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(dismiss:)];
    self.modalPresentationStyle = UIModalPresentationFormSheet;
    self.delegate = self;
    self.showDoneButton = NO;
    self.showCreditsFooter = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self filterCellsWithAnimation:NO];
}

- (NSSet *)hiddenBiometryKeys
{
    if (@available(iOS 11.0, *)) {
        LAContext *laContext = [[LAContext alloc] init];
        if ([laContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil]) {
            switch (laContext.biometryType) {
                case LABiometryTypeFaceID:
                    return [NSSet setWithObject:krqdMediaSettingPasscodeAllowTouchID];
                case LABiometryTypeTouchID:
                    return [NSSet setWithObject:krqdMediaSettingPasscodeAllowFaceID];
                case LABiometryNone:
                    return [NSSet setWithObjects:krqdMediaSettingPasscodeAllowFaceID, krqdMediaSettingPasscodeAllowTouchID, nil];
            }
        }
        return [NSSet setWithObjects:krqdMediaSettingPasscodeAllowFaceID, krqdMediaSettingPasscodeAllowTouchID, nil];
    }
    return [NSSet setWithObject:krqdMediaSettingPasscodeAllowFaceID];
}

- (void)filterCellsWithAnimation:(BOOL)shouldAnimate
{
    NSMutableSet *hideKeys = [[NSMutableSet alloc] init];
    if (![rqdMediaKeychainCoordinator passcodeLockEnabled]) {
        [hideKeys addObject:krqdMediaSettingPasscodeAllowTouchID];
        [hideKeys addObject:krqdMediaSettingPasscodeAllowFaceID];
        [self setHiddenKeys:hideKeys animated:shouldAnimate];
        return;
    }
    [self setHiddenKeys:[self hiddenBiometryKeys] animated:shouldAnimate];
}

- (void)settingDidChange:(NSNotification*)notification
{
    if ([notification.object isEqual:krqdMediaSettingPasscodeOnKey]) {
        BOOL passcodeOn = [[notification.userInfo objectForKey:krqdMediaSettingPasscodeOnKey] boolValue];

        if (passcodeOn) {
            PAPasscodeViewController *passcodeLockController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionSet];
            passcodeLockController.delegate = self;
            [self presentViewController:passcodeLockController animated:YES completion:nil];
        } else {
            [self updateForPasscode:nil];
        }
    }
}

- (void)updateUIAndCoreSpotlightForPasscodeSetting:(BOOL)passcodeOn
{
    [self filterCellsWithAnimation:YES];

    [[MLMediaLibrary sharedMediaLibrary] setSpotlightIndexingEnabled:!passcodeOn];
    if (passcodeOn) {
        // delete whole index for rqdMedia
        [[CSSearchableIndex defaultSearchableIndex] deleteAllSearchableItemsWithCompletionHandler:nil];
        rqdMediaAppDelegate *appDelegate = (rqdMediaAppDelegate *)UIApplication.sharedApplication.delegate;
        appDelegate.libraryViewController.userActivity.eligibleForSearch = false;
    }
}

#pragma mark - IASKSettings delegate

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender
{
    [[rqdMediaSidebarController sharedInstance] toggleSidebar];
}

#pragma mark - PAPasscode delegate

- (void)PAPasscodeViewControllerDidCancel:(PAPasscodeViewController *)controller
{
    [self updateForPasscode:nil];
}

- (void)PAPasscodeViewControllerDidSetPasscode:(PAPasscodeViewController *)controller
{
    [self updateForPasscode:controller.passcode];
}

- (void)updateForPasscode:(NSString *)passcode
{
    NSError *error = nil;
    [rqdMediaKeychainCoordinator setPasscodeWithPasscode:passcode error:&error];
    if (error == nil) {
        if (passcode == nil) {
            //Set manually the value to NO to disable the UISwitch.
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:krqdMediaSettingPasscodeOnKey];
        }
        [self updateUIAndCoreSpotlightForPasscodeSetting:passcode != nil];
    }
    if ([self.navigationController.presentedViewController isKindOfClass:[PAPasscodeViewController class]]) {
        [self.navigationController.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
}
@end
