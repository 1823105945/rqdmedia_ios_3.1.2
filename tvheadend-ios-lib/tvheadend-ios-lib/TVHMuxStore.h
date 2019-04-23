//
//  TVHMuxStore.h
//  TvhClient
//
//  Created by Luis Fernandes on 08/12/13.
//  Copyright (c) 2013 Luis Fernandes.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHApiClient.h"

#define TVHDvbMuxReloadNotification @"dvbMuxNotificationClassReceived"

@class TVHServer;

@protocol TVHMuxNetwork
- (NSString*)identifierForNetwork;
@end

@protocol TVHMuxStore <TVHApiClientDelegate>
@property (nonatomic, weak) TVHServer *tvhServer;
@property (strong, nonatomic) NSString *identifier; // <=3.5 has muxes per adapter, needs an identifier to fetch them
- (id)initWithTvhServer:(TVHServer*)tvhServer;
- (void)fetchMuxes;
- (NSArray*)muxesFor:(id <TVHMuxNetwork>)network;
- (NSArray*)muxesForNetwork:(id <TVHMuxNetwork>)network;
- (void)signalDidLoadAdapterMuxes;
@end
