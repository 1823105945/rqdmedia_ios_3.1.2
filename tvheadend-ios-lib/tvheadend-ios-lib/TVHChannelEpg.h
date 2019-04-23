//
//  TVHChannelEpg.h
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/11/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h>

@interface TVHChannelEpg : NSObject
@property (nonatomic, strong) NSString *date;
@property (nonatomic, strong) NSMutableArray *programs;
@end
