/*****************************************************************************
 * rqdMediaFirstStepsViewController.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaFirstStepsViewController.h"
#import "rqdMediaFirstStepsFirstPageViewController.h"
#import "rqdMediaFirstStepsSecondPageViewController.h"
#import "rqdMediaFirstStepsThirdPageViewController.h"
#import "rqdMediaFirstStepsFourthPageViewController.h"
#import "rqdMediaFirstStepsFifthPageViewController.h"
#import "rqdMediaFirstStepsSixthPageViewController.h"

@interface rqdMediaFirstStepsViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>
{
    UIPageViewController *pageVC;
}

@end

@implementation rqdMediaFirstStepsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    pageVC = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    pageVC.dataSource = self;
    pageVC.delegate = self;

    [[pageVC view] setFrame:[[self view] bounds]];

    [pageVC setViewControllers:@[[[rqdMediaFirstStepsFirstPageViewController alloc] initWithNibName:nil bundle:nil]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];

    UIBarButtonItem *dismissButton = [UIBarButtonItem themedDarkToolbarButtonWithTitle:NSLocalizedString(@"BUTTON_DONE", nil) target:self andSelector:@selector(dismissFirstSteps)];
    self.navigationItem.rightBarButtonItem = dismissButton;
    self.title = NSLocalizedString(@"FIRST_STEPS_WELCOME", nil);
    self.view.backgroundColor = [UIColor blackColor];

    [self addChildViewController:pageVC];
    [self.view addSubview:[pageVC view]];
    [pageVC didMoveToParentViewController:self];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    UIViewController *returnedVC;
    NSUInteger currentPage = 0;

    if ([viewController respondsToSelector:@selector(page)])
        currentPage = (NSUInteger)[viewController performSelector:@selector(page) withObject:nil];

    switch (currentPage) {
        case 1:
            returnedVC = [[rqdMediaFirstStepsSecondPageViewController alloc] initWithNibName:nil bundle:nil];
            break;
        case 2:
            returnedVC = [[rqdMediaFirstStepsThirdPageViewController alloc] initWithNibName:nil bundle:nil];
            break;
        case 3:
            returnedVC = [[rqdMediaFirstStepsFourthPageViewController alloc] initWithNibName:nil bundle:nil];
            break;
        case 4:
            returnedVC = [[rqdMediaFirstStepsFifthPageViewController alloc] initWithNibName:nil bundle:nil];
            break;
        case 5:
            returnedVC = [[rqdMediaFirstStepsSixthPageViewController alloc] initWithNibName:nil bundle:nil];
            break;

        default:
            nil;
    }

    return returnedVC;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    UIViewController *returnedVC;
    NSUInteger currentPage = 0;

    if ([viewController respondsToSelector:@selector(page)])
        currentPage = (NSUInteger)[viewController performSelector:@selector(page) withObject:nil];

    switch (currentPage) {
        case 2:
            returnedVC = [[rqdMediaFirstStepsFirstPageViewController alloc] initWithNibName:nil bundle:nil];
            break;
        case 3:
            returnedVC = [[rqdMediaFirstStepsSecondPageViewController alloc] initWithNibName:nil bundle:nil];
            break;
        case 4:
            returnedVC = [[rqdMediaFirstStepsThirdPageViewController alloc] initWithNibName:nil bundle:nil];
            break;
        case 5:
            returnedVC = [[rqdMediaFirstStepsFourthPageViewController alloc] initWithNibName:nil bundle:nil];
            break;
        case 6:
            returnedVC = [[rqdMediaFirstStepsFifthPageViewController alloc] initWithNibName:nil bundle:nil];
            break;

        default:
            nil;
    }

    return returnedVC;
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return 6;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
}

- (void)dismissFirstSteps
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    self.title = [[pageViewController viewControllers][0] pageTitle];
}

@end
