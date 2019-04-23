/*****************************************************************************
 * rqdMediaSidebarController.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaSidebarController.h"
#import "rqdMediaMenuTableViewController.h"
#import "UIViewController+RESideMenu.h"
#import "RESideMenu.h"
#import "UIDevice+rqdMedia.h"

@interface rqdMediaSidebarController() <RESideMenuDelegate>
{
    RESideMenu *_sideMenuViewController;
    rqdMediaMenuTableViewController *_menuViewController;
    UIViewController *_contentViewController;
    BOOL _menuVisible;
}

@end

@implementation rqdMediaSidebarController

+ (instancetype)sharedInstance
{
    static rqdMediaSidebarController *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [rqdMediaSidebarController new];
    });

    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];

    if (!self)
        return self;
    _menuViewController = [[rqdMediaMenuTableViewController alloc] initWithNibName:nil bundle:nil];
    if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionLeftToRight) {
        _sideMenuViewController = [[RESideMenu alloc] initWithContentViewController:nil
                                                             leftMenuViewController:_menuViewController
                                                            rightMenuViewController:nil];
    } else {
        _sideMenuViewController = [[RESideMenu alloc] initWithContentViewController:nil
                                                             leftMenuViewController:nil
                                                            rightMenuViewController:_menuViewController];
    }
    _sideMenuViewController.backgroundImage = [UIImage imageNamed:@"menu-background"];

    _sideMenuViewController.delegate = self;

    return self;
}

#pragma mark - VC handling

- (UIViewController *)fullViewController
{
    return _sideMenuViewController;
}

- (void)setContentViewController:(UIViewController *)contentViewController
{
    contentViewController.view.backgroundColor = [UIColor rqdMediaMenuBackgroundColor];
    _sideMenuViewController.contentViewController = contentViewController;
}

- (UIViewController *)contentViewController
{
    return _sideMenuViewController.contentViewController;
}

#pragma mark - actual work

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath scrollPosition:(UITableViewScrollPosition)scrollPosition
{
    [_menuViewController selectRowAtIndexPath:indexPath
                                     animated:NO
                               scrollPosition:scrollPosition];
}

- (void)hideSidebar
{
    _menuVisible = NO;
    [_sideMenuViewController hideMenuViewController];
}

- (void)toggleSidebar
{
    _menuVisible = YES;
    if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionLeftToRight) {
            [_sideMenuViewController presentLeftMenuViewController];
    } else {
            [_sideMenuViewController presentRightMenuViewController];
    }
}

- (void)resizeContentView
{
    if (_menuVisible) {
        [self hideSidebar];
        [self toggleSidebar];
    }
}

- (void)performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem
{
    NSString *itemType = shortcutItem.type;
    if ([itemType isEqualToString:krqdMediaApplicationShortcutLocalLibrary]) {
        [self selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] scrollPosition:UITableViewScrollPositionNone];
    } else if ([itemType isEqualToString:krqdMediaApplicationShortcutLocalServers]) {
        [self selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] scrollPosition:UITableViewScrollPositionNone];
    } else if ([itemType isEqualToString:krqdMediaApplicationShortcutOpenNetworkStream]) {
        [self selectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1] scrollPosition:UITableViewScrollPositionNone];
    } else if ([itemType isEqualToString:krqdMediaApplicationShortcutClouds]) {
        [self selectRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:1] scrollPosition:UITableViewScrollPositionNone];
    }
}

#pragma mark - RESideMenu Delegate

- (void)sideMenu:(RESideMenu *)sideMenu willHideMenuViewController:(UIViewController *)menuViewController
{
    _menuVisible = NO;
}

@end
