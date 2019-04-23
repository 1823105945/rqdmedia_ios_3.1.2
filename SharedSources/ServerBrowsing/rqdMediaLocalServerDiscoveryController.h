/*****************************************************************************
 * rqdMediaLocalServerDiscoveryController.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import "rqdMediaLocalNetworkService-Protocol.h"

@protocol rqdMediaLocalServerDiscoveryControllerDelegate <NSObject>
- (void)discoveryFoundSomethingNew;
@end

@interface rqdMediaLocalServerDiscoveryController : NSObject
@property (nonatomic, readwrite, weak) id delegate;

// array of classes conforming to rqdMediaLocalNetworkServiceBrowser
- (instancetype)initWithServiceBrowserClasses:(NSArray<Class> *)serviceBrowserClasses;

- (NSUInteger)numberOfSections;
- (NSString *)titleForSection:(NSUInteger)section;
- (NSUInteger)numberOfItemsInSection:(NSUInteger)section;
- (BOOL)foundAnythingAtAll;

- (id<rqdMediaLocalNetworkService>)networkServiceForIndexPath:(NSIndexPath *)indexPath;

- (void)stopDiscovery;
- (BOOL)refreshDiscoveredData;
- (void)startDiscovery;

@end
