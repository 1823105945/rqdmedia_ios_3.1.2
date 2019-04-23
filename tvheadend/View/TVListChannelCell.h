//
//  TVListChannelCell.h
//  rqdMedia-iOS
//
//  Created by liu_yakai on 2018/12/10.
//  Copyright © 2018年 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TVListChannelCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *channelName;
@property (weak, nonatomic) IBOutlet UILabel *currentPlayback;
@property (weak, nonatomic) IBOutlet UILabel *nextChannel;

@end
