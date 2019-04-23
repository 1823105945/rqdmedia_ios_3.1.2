/*****************************************************************************
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Vincent L. Cone <vincent.l.cone # tuta.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


#import "rqdMediaNetworkLoginDataSourceProtocol.h"

static NSString *const rqdMediaNetworkLoginDataSourceProtocolCellIdentifier = @"rqdMediaNetworkLoginDataSourceProtocolCell";

@interface  rqdMediaNetworkLoginDataSourceProtocolCell : UITableViewCell
@property (nonatomic) UISegmentedControl *segmentedControl;
@end

@interface rqdMediaNetworkLoginDataSourceProtocol ()
@property (nonatomic, weak) UITableView *tableView;
@end

@implementation rqdMediaNetworkLoginDataSourceProtocol
@synthesize sectionIndex;
- (void)segmentedControlChanged:(UISegmentedControl *)control
{
    NSInteger selectedIndex = control.selectedSegmentIndex;
    if (selectedIndex < 0 || rqdMediaServerProtocolUndefined < selectedIndex) {
        selectedIndex = rqdMediaServerProtocolUndefined;
    }
    self.protocol = (rqdMediaServerProtocol)selectedIndex;
    [self.delegate protocolDidChange:self];
}

- (void)setProtocol:(rqdMediaServerProtocol)protocol
{
    if (_protocol != protocol) {
        _protocol = protocol;
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:self.sectionIndex]];
        [self configureCell:cell forRow:0];
    }
}

#pragma mark - rqdMediaNetworkLoginDataSourceSection
- (void)configureWithTableView:(UITableView *)tableView
{
    [tableView registerClass:[rqdMediaNetworkLoginDataSourceProtocolCell class] forCellReuseIdentifier:rqdMediaNetworkLoginDataSourceProtocolCellIdentifier];
    self.tableView = tableView;
}

- (NSUInteger)numberOfRowsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)cellIdentifierForRow:(NSUInteger)row
{
    return rqdMediaNetworkLoginDataSourceProtocolCellIdentifier;
}

- (void)configureCell:(UITableViewCell *)cell forRow:(NSUInteger)row
{
    NSInteger segmentIndex = self.protocol;
    if (segmentIndex == rqdMediaServerProtocolUndefined) {
        segmentIndex = -1;
    }
    rqdMediaNetworkLoginDataSourceProtocolCell *protocolCell = [cell isKindOfClass:[rqdMediaNetworkLoginDataSourceProtocolCell class]] ? (id)cell : nil;
    protocolCell.segmentedControl.selectedSegmentIndex = segmentIndex;
    if (![[protocolCell.segmentedControl allTargets] containsObject:self]) {
        [protocolCell.segmentedControl addTarget:self action:@selector(segmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
    }
}

@end


@implementation rqdMediaNetworkLoginDataSourceProtocolCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:
                             @[NSLocalizedString(@"SMB_CIFS_FILE_SERVERS_SHORT", nil),
                               NSLocalizedString(@"FTP_SHORT", nil),
                               NSLocalizedString(@"PLEX_SHORT", nil),
                               ]];
        _segmentedControl.tintColor = [UIColor rqdMediaLightTextColor];
        [self.contentView addSubview:_segmentedControl];
        self.backgroundColor = [UIColor rqdMediaDarkBackgroundColor];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.segmentedControl.frame = CGRectInset(self.contentView.bounds, 20, 5);
}

@end
