//
//  TVListChans.h
//  rqdMedia-iOS
//
//  Created by liu_yakai on 2018/11/20.
//  Copyright © 2018年 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TVHChannel.h"

@interface TVListChannel : UITableView<UITableViewDelegate,UITableViewDataSource>
@property (strong, nonatomic) NSArray *channels;
@property (nonatomic,copy) void (^ ClockChannel)(TVHChannel *channel,NSInteger selectIndex);
@property(nonatomic,assign)NSInteger currentPlayChannel;
//是否在滚动
@property(nonatomic,copy)void (^ IsRoll)(BOOL isRoll);
@end
