/*****************************************************************************
 * rqdMediaEqualizerView.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan dot org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>
#import "rqdMediaFrostedGlasView.h"

@protocol rqdMediaEqualizerViewDelegate <NSObject>

@required
@property (readwrite) CGFloat preAmplification;
- (void)setAmplification:(CGFloat)amplification forBand:(unsigned)index;
- (CGFloat)amplificationOfBand:(unsigned)index;
- (NSArray *)equalizerProfiles;
- (void)resetEqualizerFromProfile:(unsigned)profile;

@end

@protocol rqdMediaEqualizerViewUIDelegate <NSObject>

@optional
- (void)equalizerViewReceivedUserInput;

@end

@interface rqdMediaEqualizerView : rqdMediaFrostedGlasView <UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (weak) id <rqdMediaEqualizerViewDelegate>delegate;
@property (weak) id <rqdMediaEqualizerViewUIDelegate>UIdelegate;

- (void)reloadData;

@end
