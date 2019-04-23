/*****************************************************************************
 * WKInterfaceController+rqdMediaConnectionAlert.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "WKInterfaceController+rqdMediaConnectionAlert.h"
#import <WatchConnectivity/WatchConnectivity.h>

@implementation WKInterfaceController (rqdMediaConnectionAlert)

- (void)rqdmedia_performBlockIfSessionReachable:(void(^__nullable)())reachableBlock showUnreachableAlert:(BOOL)unreachableAlert {
    [self rqdmedia_performBlockIfSessionReachable:reachableBlock showUnreachableAlert:unreachableAlert alertOKAction:nil];
}

- (void)rqdmedia_performBlockIfSessionReachable:(void(^__nullable)())reachableBlock showUnreachableAlert:(BOOL)unreachableAlert alertOKAction:(void (^ _Nullable)())okActionBlock {

    BOOL isReachable = [[WCSession defaultSession] isReachable];
    if (!isReachable && unreachableAlert) {
        WKAlertAction *okAction = [WKAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                           style:WKAlertActionStyleDefault
                                                         handler:^{
                                                             if (okActionBlock) {
                                                                 okActionBlock();
                                                             }
                                                         }];
        [self presentAlertControllerWithTitle:NSLocalizedString(@"NOT_CONNECTED_TO_PHONE_TITLE", nil)
                                      message:NSLocalizedString(@"NOT_CONNECTED_TO_PHONE_MESSAGE", nil)
                               preferredStyle:WKAlertControllerStyleAlert
                                      actions:@[okAction]];
        return;
    } else if (isReachable && reachableBlock) {
        reachableBlock();
    }
}
@end
