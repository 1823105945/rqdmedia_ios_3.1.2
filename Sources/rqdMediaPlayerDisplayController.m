/*****************************************************************************
 * rqdMediaPlayerDisplayController.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaPlayerDisplayController.h"
#import "VLCPlaybackController.h"
#import "rqdMediaMiniPlaybackView.h"
#import "rqdMediaPlaybackNavigationController.h"

#if TARGET_OS_IOS
#import "rqdMediaMovieViewController.h"
#else
#import "rqdMediaFullscreenMovieTVViewController.h"
#endif

static NSString *const rqdMediaPlayerDisplayControllerDisplayModeKey = @"rqdMediaPlayerDisplayControllerDisplayMode";

@interface rqdMediaPlayerDisplayController ()
@property (nonatomic, strong) UIViewController<rqdMediaPlaybackControllerDelegate> *movieViewController;
@property (nonatomic, strong) UIView<rqdMediaPlaybackControllerDelegate, rqdMediaMiniPlaybackViewInterface> *miniPlaybackView;
@end

@implementation rqdMediaPlayerDisplayController

+ (rqdMediaPlayerDisplayController *)sharedInstance
{
    static rqdMediaPlayerDisplayController *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [rqdMediaPlayerDisplayController new];
    });

    return sharedInstance;
}

+ (void)initialize
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{rqdMediaPlayerDisplayControllerDisplayModeKey : @(rqdMediaPlayerDisplayControllerDisplayModeFullscreen)}];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(playbackDidStart:) name:rqdMediaPlaybackControllerPlaybackDidStart object:nil];
        [notificationCenter addObserver:self selector:@selector(playbackDidFail:) name:rqdMediaPlaybackControllerPlaybackDidFail object:nil];
        [notificationCenter addObserver:self selector:@selector(playbackDidStop:) name:rqdMediaPlaybackControllerPlaybackDidStop object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupChildViewController];
}

#pragma mark - ChildViewController

- (void)setChildViewController:(UIViewController *)childViewController
{
    if (_childViewController) {
        [_childViewController willMoveToParentViewController:nil];
        [_childViewController.view removeFromSuperview];
        [_childViewController removeFromParentViewController];
    }
    _childViewController = childViewController;
    if (self.isViewLoaded) {
        [self setupChildViewController];
    }
}

- (void)setupChildViewController
{
    UIViewController *childViewController = self.childViewController;
    if (childViewController == nil)
        return;
    [self addChildViewController:childViewController];
    [self.view addSubview:childViewController.view];
    [childViewController didMoveToParentViewController:self];
}

#pragma mark - properties

- (rqdMediaPlayerDisplayControllerDisplayMode)displayMode
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:rqdMediaPlayerDisplayControllerDisplayModeKey];
}

- (void)setDisplayMode:(rqdMediaPlayerDisplayControllerDisplayMode)displayMode
{
    [[NSUserDefaults standardUserDefaults] setInteger:displayMode forKey:rqdMediaPlayerDisplayControllerDisplayModeKey];
}

- (void)viewSafeAreaInsetsDidChange
{
    if (@available(iOS 11.0, *)) {
        [super viewSafeAreaInsetsDidChange];
        CGRect frame = _miniPlaybackView.frame;
        frame.size.height = 60.0 + self.view.safeAreaInsets.bottom;
        _miniPlaybackView.frame = frame;
    }
}

- (rqdMediaPlaybackController *)playbackController {
    if (_playbackController == nil) {
        _playbackController = [rqdMediaPlaybackController sharedInstance];
    }
    return _playbackController;
}

- (UIViewController<rqdMediaPlaybackControllerDelegate> *)movieViewController
{
    if (!_movieViewController) {
#if TARGET_OS_IOS
        _movieViewController = [[rqdMediaMovieViewController alloc] initWithNibName:nil bundle:nil];
#else
        _movieViewController = [[rqdMediaFullscreenMovieTVViewController alloc] initWithNibName:nil bundle:nil];
#endif
        [rqdMediaPlaybackController sharedInstance].delegate = _movieViewController;
    }
    return _movieViewController;
}

#pragma mark - Notification Handling

- (void)playbackDidStart:(NSNotification *)notification
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL enforceFullscreen = [[defaults objectForKey:krqdMediaSettingVideoFullscreenPlayback] boolValue];

    rqdMediaPlaybackController *vpc = [rqdMediaPlaybackController sharedInstance];
    if (vpc.fullscreenSessionRequested && enforceFullscreen) {
        [self showFullscreenPlayback];
        return;
    }

    switch (self.displayMode) {
        case rqdMediaPlayerDisplayControllerDisplayModeFullscreen:
            [self _presentFullscreenPlaybackViewIfNeeded];
            break;
        case rqdMediaPlayerDisplayControllerDisplayModeMiniplayer:
            [self _showHideMiniPlaybackView];
            break;
        default:
            break;
    }
}

- (void)playbackDidStop:(NSNotification *)notification
{
    [self dismissPlaybackView];
}

- (void)playbackDidFail:(NSNotification *)notification
{
    [self showPlaybackError];
}

#pragma mark - API

- (void)showFullscreenPlayback
{
    self.displayMode = rqdMediaPlayerDisplayControllerDisplayModeFullscreen;
    [self _presentFullscreenPlaybackViewIfNeeded];
}

- (void)closeFullscreenPlayback
{
    [self _closeFullscreenPlayback];
    self.displayMode = rqdMediaPlayerDisplayControllerDisplayModeMiniplayer;
    [self _showHideMiniPlaybackView];
}

#pragma mark - presentation handling

- (BOOL)shouldAnimate
{
    return [[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground;
}

- (void)pushPlaybackView
{
    switch (self.displayMode) {
        case rqdMediaPlayerDisplayControllerDisplayModeFullscreen:
            [self _presentFullscreenPlaybackViewIfNeeded];
            break;
        case rqdMediaPlayerDisplayControllerDisplayModeMiniplayer:
            [self _showHideMiniPlaybackView];
        default:
            break;
    }
}

- (void)dismissPlaybackView
{
    switch (self.displayMode) {
        case rqdMediaPlayerDisplayControllerDisplayModeFullscreen:
            [self _closeFullscreenPlayback];
            break;
        case rqdMediaPlayerDisplayControllerDisplayModeMiniplayer:
            [self _showHideMiniPlaybackView];
        default:
            break;
    }
}

- (void)showPlaybackError
{
    NSString *failedString = NSLocalizedString(@"PLAYBACK_FAILED", nil);
#if TARGET_OS_IOS
    switch (self.displayMode) {
        case rqdMediaPlayerDisplayControllerDisplayModeFullscreen:
            if ([self.movieViewController respondsToSelector:@selector(showStatusMessage:forPlaybackController:)]) {
                [self.movieViewController showStatusMessage:failedString forPlaybackController:nil];
            }
            break;
        case rqdMediaPlayerDisplayControllerDisplayModeMiniplayer:
        default:

            [[[rqdMediaAlertView alloc] initWithTitle:failedString
                                         message:nil
                                        delegate:nil
                               cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                               otherButtonTitles:nil] show];
            break;
    }
#else
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:failedString
                                                                   message:@""
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];

    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
#endif
}

#pragma mark - fullscreen player

- (void)_presentFullscreenPlaybackViewIfNeeded
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.movieViewController.presentingViewController) {
            [self _presentMovieViewControllerAnimated:[self shouldAnimate]];
        }
    });
}

- (void)_closeFullscreenPlayback
{
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL animated = [self shouldAnimate];
        [self.movieViewController dismissViewControllerAnimated:animated completion:nil];
        [self _showHideMiniPlaybackView];
    });
}

- (void)_presentMovieViewControllerAnimated:(BOOL)animated
{
    UIViewController<rqdMediaPlaybackControllerDelegate> *movieViewController = self.movieViewController;
    UINavigationController *navCon = [[rqdMediaPlaybackNavigationController alloc] initWithRootViewController:movieViewController];
    [movieViewController prepareForMediaPlayback:self.playbackController];

    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [window.rootViewController presentViewController:navCon animated:animated completion:nil];
}

#pragma mark - miniplayer

- (void)_showHideMiniPlaybackView
{
#if TARGET_OS_TV
    return;
#else
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(_showHideMiniPlaybackView) withObject:nil waitUntilDone:NO];
        return;
    }

    rqdMediaPlaybackController *playbackController = [rqdMediaPlaybackController sharedInstance];
    UIView<rqdMediaPlaybackControllerDelegate, rqdMediaMiniPlaybackViewInterface> *miniPlaybackView = self.miniPlaybackView;
    const NSTimeInterval animationDuration = 0.25;
    const BOOL activePlaybackSession = playbackController.isPlaying || playbackController.willPlay;
    const BOOL miniPlayerVisible = miniPlaybackView.visible;

    const CGRect viewRect = self.view.bounds;

    CGFloat miniPlayerHeight = 60.;
    if (@available(iOS 11.0, *)) {
        miniPlayerHeight += self.view.safeAreaInsets.bottom;
    }
    const CGRect miniPlayerFrameIn =  CGRectMake(0., viewRect.size.height-miniPlayerHeight, viewRect.size.width, miniPlayerHeight);
    const CGRect miniPlayerFrameOut = CGRectMake(0., viewRect.size.height, viewRect.size.width, miniPlayerHeight);

    BOOL needsShow = activePlaybackSession && !miniPlayerVisible;
    BOOL needsHide = !activePlaybackSession && miniPlayerVisible;

    if (self.editing) {
        needsHide = YES;
        needsShow = NO;
    }

    void (^completionBlock)(BOOL) = nil;
    if (needsShow) {
        if (!miniPlaybackView) {
            self.miniPlaybackView = miniPlaybackView = [[rqdMediaMiniPlaybackView alloc] initWithFrame:miniPlayerFrameOut];
            miniPlaybackView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
            [self.view addSubview:miniPlaybackView];
        }
        miniPlaybackView.visible = YES;
    } else if (needsHide) {
        miniPlaybackView.visible = NO;
        completionBlock = ^(BOOL finished) {
            UIView<rqdMediaPlaybackControllerDelegate, rqdMediaMiniPlaybackViewInterface> *miniPlaybackView = self.miniPlaybackView;
            if (miniPlaybackView.visible == NO) {
                [miniPlaybackView removeFromSuperview];
                self.miniPlaybackView = nil;
            }
        };
    }
    //when switching between tableview and collectionview all subviews are removed, make sure to readd it when this happens
    if (!miniPlaybackView.superview && miniPlayerVisible) {
        [self.view addSubview:miniPlaybackView];
    }
    // either way update view
    [miniPlaybackView prepareForMediaPlayback:playbackController];

    if (needsShow || needsHide) {
        UIViewController *childViewController = self.childViewController;

        const CGRect newMiniPlayerFrame = needsHide ? miniPlayerFrameOut : miniPlayerFrameIn;
        CGRect newChildViewFrame = childViewController.view.frame;
        newChildViewFrame.size.height = CGRectGetMinY(newMiniPlayerFrame)-CGRectGetMinY(newChildViewFrame);

        [UIView animateWithDuration:animationDuration
                              delay:animationDuration
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             miniPlaybackView.frame = newMiniPlayerFrame;
                             childViewController.view.frame = newChildViewFrame;
                         }
                         completion:completionBlock];
    }
#endif
}

@end
