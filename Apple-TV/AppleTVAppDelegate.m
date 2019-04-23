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

#import "AppleTVAppDelegate.h"
#import "rqdMediaServerListTVViewController.h"
#import "rqdMediaOpenNetworkStreamTVViewController.h"
#import "rqdMediaSettingsViewController.h"
#import "rqdMediaCloudServicesTVViewController.h"
#import "rqdMediaHTTPUploaderController.h"
#import "rqdMediaRemotePlaybackViewController.h"
#import <HockeySDK/HockeySDK.h>

@interface AppleTVAppDelegate ()
{
    UITabBarController *_mainViewController;

    rqdMediaServerListTVViewController *_localNetworkVC;
    rqdMediaCloudServicesTVViewController *_cloudServicesVC;
    rqdMediaRemotePlaybackViewController *_remotePlaybackVC;
    rqdMediaOpenNetworkStreamTVViewController *_openNetworkVC;
    rqdMediaSettingsViewController *_settingsVC;
}

@end

@implementation AppleTVAppDelegate

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *appDefaults = @{krqdMediaSettingContinueAudioInBackgroundKey : @(YES),
                                  krqdMediaSettingStretchAudio : @(YES),
                                  krqdMediaSettingTextEncoding : krqdMediaSettingTextEncodingDefaultValue,
                                  krqdMediaSettingSkipLoopFilter : krqdMediaSettingSkipLoopFilterNonRef,
                                  krqdMediaSettingSubtitlesFont : krqdMediaSettingSubtitlesFontDefaultValue,
                                  krqdMediaSettingSubtitlesFontColor : krqdMediaSettingSubtitlesFontColorDefaultValue,
                                  krqdMediaSettingSubtitlesFontSize : krqdMediaSettingSubtitlesFontSizeDefaultValue,
                                  krqdMediaSettingSubtitlesBoldFont: krqdMediaSettingSubtitlesBoldFontDefaultValue,
                                  krqdMediaSettingDeinterlace : krqdMediaSettingDeinterlaceDefaultValue,
                                  krqdMediaSettingHardwareDecoding : krqdMediaSettingHardwareDecodingDefault,
                                  krqdMediaSettingNetworkCaching : krqdMediaSettingNetworkCachingDefaultValue,
                                  krqdMediaSettingEqualizerProfile : krqdMediaSettingEqualizerProfileDefaultValue,
                                  krqdMediaSettingPlaybackForwardSkipLength : krqdMediaSettingPlaybackForwardSkipLengthDefaultValue,
                                  krqdMediaSettingPlaybackBackwardSkipLength : krqdMediaSettingPlaybackBackwardSkipLengthDefaultValue,
                                  krqdMediaSettingFTPTextEncoding : krqdMediaSettingFTPTextEncodingDefaultValue,
                                  krqdMediaSettingWiFiSharingIPv6 : krqdMediaSettingWiFiSharingIPv6DefaultValue,
                                  krqdMediaAutomaticallyPlayNextItem : @(YES),
                                  krqdMediaSettingDownloadArtwork : @(YES)};
    [defaults registerDefaults:appDefaults];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    BITHockeyManager *hockeyManager = [BITHockeyManager sharedHockeyManager];
    [hockeyManager configureWithIdentifier:@"f8697706993b44bba1c03cb7016cc325"];

    // Configure the SDK in here only!
    [hockeyManager startManager];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _localNetworkVC = [[rqdMediaServerListTVViewController alloc] initWithNibName:nil bundle:nil];
    _remotePlaybackVC = [[rqdMediaRemotePlaybackViewController alloc] initWithNibName:nil bundle:nil];
    _openNetworkVC = [[rqdMediaOpenNetworkStreamTVViewController alloc] initWithNibName:nil bundle:nil];
    _settingsVC = [[rqdMediaSettingsViewController alloc] initWithNibName:nil bundle:nil];

    _mainViewController = [[UITabBarController alloc] init];
    _mainViewController.tabBar.barTintColor = [UIColor rqdMediaOrangeTintColor];

    _mainViewController.viewControllers = @[[[UINavigationController alloc] initWithRootViewController:_localNetworkVC],
                                            [[UINavigationController alloc] initWithRootViewController:_remotePlaybackVC],
                                            [[UINavigationController alloc] initWithRootViewController:_openNetworkVC],
                                            [[UINavigationController alloc] initWithRootViewController:_settingsVC]];

    self.window.rootViewController = _mainViewController;

    // Init the HTTP Server
    [rqdMediaHTTPUploaderController sharedInstance];

    [self.window makeKeyAndVisible];
    return YES;
}

@end
