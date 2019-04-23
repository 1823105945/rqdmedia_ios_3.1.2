/*****************************************************************************
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaPlaybackInfoTVAnimators.h"
#import "rqdMediaPlaybackInfoTVViewController.h"

@implementation rqdMediaPlaybackInfoTabBarTVTransitioningAnimator

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.3;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *source = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *target = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    UIView *sourceView = source.view;
    UIView *targetView = target.view;

    UIView *container = [transitionContext containerView];

    CGRect oldContainerBounds = container.bounds;
    CGPoint oldCenter = CGPointMake(CGRectGetMidX(oldContainerBounds), CGRectGetMidY(oldContainerBounds));

    CGSize targetSize = target.preferredContentSize;
    CGPoint newCenter = CGPointMake(targetSize.width/2.0, targetSize.height/2.0);

    targetView.alpha = 0.0;
    targetView.frame = CGRectMake(0, 0, targetSize.width, targetSize.height);
    targetView.center = oldCenter;
    [targetView layoutIfNeeded];
    [container addSubview:targetView];

    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                     animations:^{

                         sourceView.center = newCenter;
                         sourceView.alpha = 0.0;

                         targetView.center = newCenter;
                         targetView.alpha = 1.0;

                         [self.infoContainerViewController updateViewConstraints];
                         [self.infoContainerViewController.view layoutIfNeeded];

                     } completion:^(BOOL finished) {
                         [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
                     }];
}

@end


@implementation rqdMediaPlaybackInfoTVTransitioningAnimator

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.5;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *source = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *target = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    UIView *container = [transitionContext containerView];
    CGRect initialSourceFrame = [transitionContext initialFrameForViewController:source];
    // TODO: calculate
    CGFloat infoHeight = CGRectGetHeight(initialSourceFrame);

    CGRect largeFrame = ({
        CGRect frame = initialSourceFrame;
        frame.origin.y -=infoHeight;
        frame.size.height += infoHeight;
        frame;
    });
    CGRect smallFrame = initialSourceFrame;

    CGFloat targetAlpha = 1.0;
    CGRect fromFrame = initialSourceFrame;
    CGRect toFrame = initialSourceFrame;

    rqdMediaPlaybackInfoTVViewController *infoVC = nil;
    if ([target isKindOfClass:[rqdMediaPlaybackInfoTVViewController class]]) {
        infoVC = (rqdMediaPlaybackInfoTVViewController*) target;
        infoVC.dimmingView.alpha = 0.0;
        targetAlpha = 1.0;
        toFrame = smallFrame;
        fromFrame = largeFrame;
        [container addSubview:target.view];
    } else if ([source isKindOfClass:[rqdMediaPlaybackInfoTVViewController class]]) {
        infoVC = (rqdMediaPlaybackInfoTVViewController*) source;
        infoVC.dimmingView.alpha = 1.0;
        targetAlpha = 0.0;
        toFrame = largeFrame;
        fromFrame = smallFrame;
    }

    infoVC.view.frame = fromFrame;
    [infoVC updateViewConstraints];
    [infoVC.view layoutIfNeeded];

    // fallback
    if (!infoVC) {
        target.view.frame = smallFrame;
    }

    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                     animations:^{
                         infoVC.view.frame = toFrame;
                         [infoVC.view layoutIfNeeded];
                         infoVC.dimmingView.alpha = targetAlpha;
                     }
                     completion:^(BOOL finished) {
                         [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
                     }];
    
}

@end