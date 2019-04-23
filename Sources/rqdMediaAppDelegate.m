/*****************************************************************************
 * rqdMediaAppDelegate.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Jean-Romain Prévost <jr # 3on.fr>
 *          Luis Fernandes <zipleen # gmail.com>
 *          Carola Nitz <nitz.carola # googlemail.com>
 *          Tamas Timar <ttimar.rqdmedia # gmail.com>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *          Soomin Lee <TheHungryBu # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaAppDelegate.h"
#import "VLCMediaFileDiscoverer.h"
#import "NSString+SupportedMedia.h"
#import "UIDevice+rqdMedia.h"
#import "VLCLibraryViewController.h"
#import "rqdMediaHTTPUploaderController.h"
#import "rqdMediaMigrationViewController.h"
#import <BoxSDK/BoxSDK.h>
#import "VLCPlaybackController.h"
#import "rqdMediaPlaybackController+MediaLibrary.h"
#import "rqdMediaPlayerDisplayController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <HockeySDK/HockeySDK.h>
#import "rqdMediaSidebarController.h"
#import "rqdMediaActivityManager.h"
#import "rqdMediaDropboxConstants.h"
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>
#import "rqdMediaPlaybackNavigationController.h"
#import "PAPasscodeViewController.h"
#import "rqdMedia_iOS-Swift.h"
#import <UMCommon/UMCommon.h>
#import <UMCommonLog/UMCommonLogHeaders.h>
#import "MainController.h"
#define UMKey @"5c0f1ea0b465f5bc5800011a"

NSString *const rqdMediaDropboxSessionWasAuthorized = @"rqdMediaDropboxSessionWasAuthorized";

#define BETA_DISTRIBUTION 1

@interface rqdMediaAppDelegate () <VLCMediaFileDiscovererDelegate>
{
    BOOL _isRunningMigration;
    BOOL _isComingFromHandoff;
    rqdMediaWatchCommunication *_watchCommunication;
    rqdMediaKeychainCoordinator *_keychainCoordinator;
}

@end

@implementation rqdMediaAppDelegate


+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *appDefaults = @{krqdMediaSettingPasscodeAllowFaceID : @(1),
                                  krqdMediaSettingPasscodeAllowTouchID : @(1),
                                  krqdMediaSettingContinueAudioInBackgroundKey : @(YES),
                                  krqdMediaSettingStretchAudio : @(NO),
                                  krqdMediaSettingTextEncoding : krqdMediaSettingTextEncodingDefaultValue,
                                  krqdMediaSettingSkipLoopFilter : krqdMediaSettingSkipLoopFilterNonRef,
                                  krqdMediaSettingSubtitlesFont : krqdMediaSettingSubtitlesFontDefaultValue,
                                  krqdMediaSettingSubtitlesFontColor : krqdMediaSettingSubtitlesFontColorDefaultValue,
                                  krqdMediaSettingSubtitlesFontSize : krqdMediaSettingSubtitlesFontSizeDefaultValue,
                                  krqdMediaSettingSubtitlesBoldFont: krqdMediaSettingSubtitlesBoldFontDefaultValue,
                                  krqdMediaSettingDeinterlace : krqdMediaSettingDeinterlaceDefaultValue,
                                  krqdMediaSettingHardwareDecoding : krqdMediaSettingHardwareDecodingDefault,
                                  krqdMediaSettingNetworkCaching : krqdMediaSettingNetworkCachingDefaultValue,
                                  krqdMediaSettingVolumeGesture : @(YES),
                                  krqdMediaSettingPlayPauseGesture : @(YES),
                                  krqdMediaSettingBrightnessGesture : @(YES),
                                  krqdMediaSettingSeekGesture : @(YES),
                                  krqdMediaSettingCloseGesture : @(YES),
                                  krqdMediaSettingVariableJumpDuration : @(NO),
                                  krqdMediaSettingVideoFullscreenPlayback : @(YES),
                                  krqdMediaSettingContinuePlayback : @(1),
                                  krqdMediaSettingContinueAudioPlayback : @(1),
                                  krqdMediaSettingFTPTextEncoding : krqdMediaSettingFTPTextEncodingDefaultValue,
                                  krqdMediaSettingWiFiSharingIPv6 : krqdMediaSettingWiFiSharingIPv6DefaultValue,
                                  krqdMediaSettingEqualizerProfile : krqdMediaSettingEqualizerProfileDefaultValue,
                                  krqdMediaSettingPlaybackForwardSkipLength : krqdMediaSettingPlaybackForwardSkipLengthDefaultValue,
                                  krqdMediaSettingPlaybackBackwardSkipLength : krqdMediaSettingPlaybackBackwardSkipLengthDefaultValue,
                                  krqdMediaSettingOpenAppForPlayback : krqdMediaSettingOpenAppForPlaybackDefaultValue,
                                  krqdMediaAutomaticallyPlayNextItem : @(YES)};
    [defaults registerDefaults:appDefaults];
}

-(void)initUM{
    [UMCommonLogManager setUpUMCommonLogManager];
    [UMConfigure setLogEnabled:YES];
    [UMConfigure initWithAppkey:UMKey channel:@"App Store"];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self initUM];
    BITHockeyManager *hockeyManager = [BITHockeyManager sharedHockeyManager];
    [hockeyManager configureWithBetaIdentifier:@"0114ca8e265244ce588d2ebd035c3577"
                                liveIdentifier:@"c95f4227dff96c61f8b3a46a25edc584"
                                      delegate:nil];
    [hockeyManager startManager];

    // Configure Dropbox
    [DBClientsManager setupWithAppKey:krqdMediaDropboxAppKey];

    [self setupAppearence];

    // Init the HTTP Server and clean its cache
    [[rqdMediaHTTPUploaderController sharedInstance] cleanCache];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // enable crash preventer
    void (^setupBlock)() = ^{
        __weak typeof(self) weakSelf = self;
        void (^setupLibraryBlock)() = ^{
            _libraryViewController = [[VLCLibraryViewController alloc] init];
            UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:_libraryViewController];

            rqdMediaSidebarController *sidebarVC = [rqdMediaSidebarController sharedInstance];
            sidebarVC.contentViewController = navCon;

            rqdMediaPlayerDisplayController *playerDisplayController = [rqdMediaPlayerDisplayController sharedInstance];
            playerDisplayController.childViewController = sidebarVC.fullViewController;
            MainController *controller=[[MainController alloc]initWithNibName:@"MainController" bundle:nil];
            UINavigationController *navCon1 = [[UINavigationController alloc] initWithRootViewController:controller];
            weakSelf.window.rootViewController = navCon1;
        };
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:[[UIViewController alloc] init]];
        self.window.rootViewController = navCon;
        [self.window makeKeyAndVisible];
        [self validatePasscodeIfNeededWithCompletion:setupLibraryBlock];

        BOOL spotlightEnabled = ![rqdMediaKeychainCoordinator passcodeLockEnabled];
        [[MLMediaLibrary sharedMediaLibrary] setSpotlightIndexingEnabled:spotlightEnabled];
        [[MLMediaLibrary sharedMediaLibrary] applicationWillStart];

        VLCMediaFileDiscoverer *discoverer = [VLCMediaFileDiscoverer sharedInstance];
        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        discoverer.directoryPath = [searchPaths firstObject];
        [discoverer addObserver:self];
        [discoverer startDiscovering];
    };

    NSError *error = nil;

    if ([[MLMediaLibrary sharedMediaLibrary] libraryMigrationNeeded]){
        _isRunningMigration = YES;

        rqdMediaMigrationViewController *migrationController = [[rqdMediaMigrationViewController alloc] initWithNibName:@"rqdMediaMigrationViewController" bundle:nil];
        migrationController.completionHandler = ^{

            //migrate
            setupBlock();
            _isRunningMigration = NO;
            [[MLMediaLibrary sharedMediaLibrary] updateMediaDatabase];
            [[VLCMediaFileDiscoverer sharedInstance] updateMediaList];
        };

        self.window.rootViewController = migrationController;
        [self.window makeKeyAndVisible];

    } else {
        if (error != nil) {
            APLog(@"removed persistentStore since it was corrupt");
            NSURL *storeURL = ((MLMediaLibrary *)[MLMediaLibrary sharedMediaLibrary]).persistentStoreURL;
            [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error];
        }
        setupBlock();
    }

    if ([rqdMediaWatchCommunication isSupported]) {
        _watchCommunication = [rqdMediaWatchCommunication sharedInstance];
        // TODO: push DB changes instead
        //    [_watchCommunication startRelayingNotificationName:NSManagedObjectContextDidSaveNotification object:nil];
        [_watchCommunication startRelayingNotificationName:rqdMediaPlaybackControllerPlaybackMetadataDidChange object:nil];
    }

    /* add our static shortcut items the dynamic way to ease l10n and dynamic elements to be introduced later */
    if (@available(iOS 9, *)) {
        if (application.shortcutItems == nil || application.shortcutItems.count < 4) {
            UIApplicationShortcutItem *localLibraryItem = [[UIApplicationShortcutItem alloc] initWithType:krqdMediaApplicationShortcutLocalLibrary
                                                                                           localizedTitle:NSLocalizedString(@"SECTION_HEADER_LIBRARY",nil)
                                                                                        localizedSubtitle:nil
                                                                                                     icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"AllFiles"]
                                                                                                 userInfo:nil];
            UIApplicationShortcutItem *localServerItem = [[UIApplicationShortcutItem alloc] initWithType:krqdMediaApplicationShortcutLocalServers
                                                                                           localizedTitle:NSLocalizedString(@"LOCAL_NETWORK",nil)
                                                                                        localizedSubtitle:nil
                                                                                                     icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"Local"]
                                                                                                 userInfo:nil];
            UIApplicationShortcutItem *openNetworkStreamItem = [[UIApplicationShortcutItem alloc] initWithType:krqdMediaApplicationShortcutOpenNetworkStream
                                                                                           localizedTitle:NSLocalizedString(@"OPEN_NETWORK",nil)
                                                                                        localizedSubtitle:nil
                                                                                                     icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"OpenNetStream"]
                                                                                                 userInfo:nil];
            UIApplicationShortcutItem *cloudsItem = [[UIApplicationShortcutItem alloc] initWithType:krqdMediaApplicationShortcutClouds
                                                                                           localizedTitle:NSLocalizedString(@"CLOUD_SERVICES",nil)
                                                                                        localizedSubtitle:nil
                                                                                                     icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"iCloudIcon"]
                                                                                                 userInfo:nil];
            application.shortcutItems = @[localLibraryItem, localServerItem, openNetworkStreamItem, cloudsItem];
        }
    }

    return YES;
}

- (void)setupAppearence
{
    UIColor *rqdmediaOrange = [UIColor rqdMediaOrangeTintColor];
    // Change the keyboard for UISearchBar
    [[UITextField appearance] setKeyboardAppearance:UIKeyboardAppearanceDark];
    // For the cursor
    [[UITextField appearance] setTintColor:rqdmediaOrange];
    // Don't override the 'Cancel' button color in the search bar with the previous UITextField call. Use the default blue color
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setTitleTextAttributes:@{[UIColor whiteColor] : NSForegroundColorAttributeName} forState:UIControlStateNormal];

    [[UINavigationBar appearance] setBarTintColor:rqdmediaOrange];
    [[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[[rqdMediaPlaybackNavigationController class]]] setBarTintColor: nil];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes: @{ NSForegroundColorAttributeName : [UIColor whiteColor] }];
    // For the edit selection indicators
    [[UITableView appearance] setTintColor:rqdmediaOrange];
    [[UISwitch appearance] setOnTintColor:rqdmediaOrange];
    [[UISearchBar appearance] setBarTintColor:rqdmediaOrange];
    [[UISearchBar appearance] setTintColor:[UIColor whiteColor]];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Handoff

- (BOOL)application:(UIApplication *)application willContinueUserActivityWithType:(NSString *)userActivityType
{
    if ([userActivityType isEqualToString:krqdMediaUserActivityLibraryMode] ||
        [userActivityType isEqualToString:krqdMediaUserActivityPlaying] ||
        [userActivityType isEqualToString:krqdMediaUserActivityLibrarySelection])
        return YES;

    return NO;
}

- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray *))restorationHandler
{
    NSString *userActivityType = userActivity.activityType;
    NSDictionary *dict = userActivity.userInfo;
    if([userActivityType isEqualToString:krqdMediaUserActivityLibraryMode] ||
       [userActivityType isEqualToString:krqdMediaUserActivityLibrarySelection]) {

        VLCLibraryMode libraryMode = (VLCLibraryMode)[(NSNumber *)dict[@"state"] integerValue];

        if (libraryMode <= VLCLibraryModeAllSeries) {
            [[rqdMediaSidebarController sharedInstance] selectRowAtIndexPath:[NSIndexPath indexPathForRow:libraryMode inSection:0]
                                                         scrollPosition:UITableViewScrollPositionTop];
            [self.libraryViewController setLibraryMode:libraryMode];
        }

        [self.libraryViewController restoreUserActivityState:userActivity];
        _isComingFromHandoff = YES;
        return YES;
    } else {
        NSURL *uriRepresentation = nil;
        if ([userActivityType isEqualToString:CSSearchableItemActionType]) {
            uriRepresentation = [NSURL URLWithString:dict[CSSearchableItemActivityIdentifier]];
        } else {
            uriRepresentation = dict[@"playingmedia"];
        }

        if (!uriRepresentation) {
            return NO;
        }

        NSManagedObject *managedObject = [[MLMediaLibrary sharedMediaLibrary] objectForURIRepresentation:uriRepresentation];
        if (managedObject == nil) {
            APLog(@"%s file not found: %@",__PRETTY_FUNCTION__,userActivity);
            return NO;
        }
        [[rqdMediaPlaybackController sharedInstance] openMediaLibraryObject:managedObject];
        return YES;
    }
    return NO;
}

- (void)application:(UIApplication *)application
didFailToContinueUserActivityWithType:(NSString *)userActivityType
              error:(NSError *)error
{
    if (error.code != NSUserCancelledError){
        //TODO: present alert
    }
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    //Handles Dropbox Authorization flow.
    DBOAuthResult *authResult = [DBClientsManager handleRedirectURL:url];
    if (authResult != nil) {
        if ([authResult isSuccess]) {
            return YES;
        }
    }

    //Handles Google Authorization flow.
    if ([_currentGoogleAuthorizationFlow resumeAuthorizationFlowWithURL:url]) {
        _currentGoogleAuthorizationFlow = nil;
        return YES;
    }

    if (_libraryViewController && url != nil) {
        APLog(@"requested %@ to be opened", url);

        if (url.isFileURL) {
            rqdMediaDocumentClass *subclass = [[rqdMediaDocumentClass alloc] initWithFileURL:url];
            [subclass openWithCompletionHandler:^(BOOL success) {
                [self playWithURL:url completion:^(BOOL success) {
                    [subclass closeWithCompletionHandler:nil];
                }];
            }];
        } else if ([url.scheme isEqualToString:@"rqdmedia-x-callback"] || [url.host isEqualToString:@"x-callback-url"]) {
            // URL confirmes to the x-callback-url specification
            // rqdmedia-x-callback://x-callback-url/action?param=value&x-success=callback
            APLog(@"x-callback-url with host '%@' path '%@' parameters '%@'", url.host, url.path, url.query);
            NSString *action = [url.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
            NSURL *movieURL;
            NSURL *successCallback;
            NSURL *errorCallback;
            NSString *fileName;
            for (NSString *entry in [url.query componentsSeparatedByString:@"&"]) {
                NSArray *keyvalue = [entry componentsSeparatedByString:@"="];
                if (keyvalue.count < 2) continue;
                NSString *key = keyvalue[0];
                NSString *value = [keyvalue[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

                if ([key isEqualToString:@"url"])
                    movieURL = [NSURL URLWithString:value];
                else if ([key isEqualToString:@"filename"])
                    fileName = value;
                else if ([key isEqualToString:@"x-success"])
                    successCallback = [NSURL URLWithString:value];
                else if ([key isEqualToString:@"x-error"])
                    errorCallback = [NSURL URLWithString:value];
            }
            if ([action isEqualToString:@"stream"] && movieURL) {
                [self playWithURL:movieURL completion:^(BOOL success) {
                    NSURL *callback = success ? successCallback : errorCallback;
                    if (@available(iOS 10, *)) {
                         [[UIApplication sharedApplication] openURL:callback options:@{} completionHandler:nil];
                    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                        /* UIApplication's replacement calls require iOS 10 or later, which we can't enforce as of yet */
                       [[UIApplication sharedApplication] openURL:callback];
#pragma clang diagnostic pop
                    }
                }];
            }
            else if ([action isEqualToString:@"download"] && movieURL) {
                [self downloadMovieFromURL:movieURL fileNameOfMedia:fileName];
            }
        } else {
            NSString *receivedUrl = [url absoluteString];
            if ([receivedUrl length] > 6) {
                NSString *verifyVlcUrl = [receivedUrl substringToIndex:6];
                if ([verifyVlcUrl isEqualToString:@"rqdmedia://"]) {
                    NSString *parsedString = [receivedUrl substringFromIndex:6];
                    NSUInteger location = [parsedString rangeOfString:@"//"].location;

                    /* Safari & al mangle rqdmedia://http:// so fix this */
                    if (location != NSNotFound && [parsedString characterAtIndex:location - 1] != 0x3a) { // :
                            parsedString = [NSString stringWithFormat:@"%@://%@", [parsedString substringToIndex:location], [parsedString substringFromIndex:location+2]];
                    } else {
                        parsedString = [receivedUrl substringFromIndex:6];
                        if (![parsedString hasPrefix:@"http://"] && ![parsedString hasPrefix:@"https://"] && ![parsedString hasPrefix:@"ftp://"]) {
                            parsedString = [@"http://" stringByAppendingString:[receivedUrl substringFromIndex:6]];
                        }
                    }
                    url = [NSURL URLWithString:parsedString];
                }
            }
            [[rqdMediaSidebarController sharedInstance] selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                                         scrollPosition:UITableViewScrollPositionNone];

            NSString *scheme = url.scheme;
            if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"] || [scheme isEqualToString:@"ftp"]) {
                rqdMediaAlertView *alert = [[rqdMediaAlertView alloc] initWithTitle:NSLocalizedString(@"OPEN_STREAM_OR_DOWNLOAD", nil) message:url.absoluteString cancelButtonTitle:NSLocalizedString(@"BUTTON_DOWNLOAD", nil) otherButtonTitles:@[NSLocalizedString(@"PLAY_BUTTON", nil)]];
                alert.completion = ^(BOOL cancelled, NSInteger buttonIndex) {
                    if (cancelled)
                        [self downloadMovieFromURL:url fileNameOfMedia:nil];
                    else {
                        [self playWithURL:url completion:nil];
                    }
                };
                [alert show];
            } else {
                [self playWithURL:url completion:nil];
            }
        }
        return YES;
    }
    return NO;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[MLMediaLibrary sharedMediaLibrary] applicationWillStart];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    //Touch ID is shown 
    if ([_window.rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]){
        UINavigationController *navCon = (UINavigationController *)_window.rootViewController.presentedViewController;
        if ([navCon.topViewController isKindOfClass:[PAPasscodeViewController class]]){
            return;
        }
    }
    __weak typeof(self) weakself = self;
    [self validatePasscodeIfNeededWithCompletion:^{
        [weakself.libraryViewController updateViewContents];
        if ([rqdMediaPlaybackController sharedInstance].isPlaying){
            [[rqdMediaPlayerDisplayController sharedInstance] pushPlaybackView];
        }
    }];
    [[MLMediaLibrary sharedMediaLibrary] applicationWillExit];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (!_isRunningMigration && !_isComingFromHandoff) {
        [[MLMediaLibrary sharedMediaLibrary] updateMediaDatabase];
        [[VLCMediaFileDiscoverer sharedInstance] updateMediaList];
    } else if(_isComingFromHandoff) {
        _isComingFromHandoff = NO;
    }
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler
{
    [[rqdMediaSidebarController sharedInstance] performActionForShortcutItem:shortcutItem];
}

#pragma mark - media discovering

- (void)mediaFileAdded:(NSString *)fileName loading:(BOOL)isLoading
{
    if (!isLoading) {
        MLMediaLibrary *sharedLibrary = [MLMediaLibrary sharedMediaLibrary];
        [sharedLibrary addFilePaths:@[fileName]];

        /* exclude media files from backup (QA1719) */
        NSURL *excludeURL = [NSURL fileURLWithPath:fileName];
        [excludeURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];

        // TODO Should we update media db after adding new files?
        [sharedLibrary updateMediaDatabase];
        [_libraryViewController updateViewContents];
    }
}

- (void)mediaFileDeleted:(NSString *)name
{
    [[MLMediaLibrary sharedMediaLibrary] updateMediaDatabase];
    [_libraryViewController updateViewContents];
}

- (void)mediaFilesFoundRequiringAdditionToStorageBackend:(NSArray<NSString *> *)foundFiles
{
    [[MLMediaLibrary sharedMediaLibrary] addFilePaths:foundFiles];
    [[(rqdMediaAppDelegate *)[UIApplication sharedApplication].delegate libraryViewController] updateViewContents];
}

#pragma mark - pass code validation
- (rqdMediaKeychainCoordinator *)keychainCoordinator
{
    if (!_keychainCoordinator) {
        _keychainCoordinator = [[rqdMediaKeychainCoordinator alloc] init];
    }
    return _keychainCoordinator;
}

- (void)validatePasscodeIfNeededWithCompletion:(void(^)(void))completion
{
    if ([rqdMediaKeychainCoordinator passcodeLockEnabled]) {
        [[rqdMediaPlayerDisplayController sharedInstance] dismissPlaybackView];
        [self.keychainCoordinator validatePasscodeWithCompletion:completion];
    } else {
        completion();
    }
}

#pragma mark - download handling

- (void)downloadMovieFromURL:(NSURL *)url
             fileNameOfMedia:(NSString *)fileName
{
    [[rqdMediaDownloadViewController sharedInstance] addURLToDownloadList:url fileNameOfMedia:fileName];
    [[rqdMediaSidebarController sharedInstance] selectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]
                                                 scrollPosition:UITableViewScrollPositionNone];
}

#pragma mark - playback
- (void)playWithURL:(NSURL *)url completion:(void (^ __nullable)(BOOL success))completion
{
    rqdMediaPlaybackController *vpc = [rqdMediaPlaybackController sharedInstance];
    vpc.fullscreenSessionRequested = YES;
    VLCMediaList *mediaList = [[VLCMediaList alloc] initWithArray:@[[VLCMedia mediaWithURL:url]]];
    [vpc playMediaList:mediaList firstIndex:0 subtitlesFilePath:nil completion:completion];
}

#pragma mark - watch stuff
- (void)application:(UIApplication *)application
handleWatchKitExtensionRequest:(NSDictionary *)userInfo
              reply:(void (^)(NSDictionary *))reply
{
    if ([rqdMediaWatchCommunication isSupported]) {
        [self.watchCommunication session:[WCSession defaultSession] didReceiveMessage:userInfo replyHandler:reply];
    }
}

@end
