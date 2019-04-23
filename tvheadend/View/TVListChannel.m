//
//  TVListChans.m
//  rqdMedia-iOS
//
//  Created by liu_yakai on 2018/11/20.
//  Copyright © 2018年 VideoLAN. All rights reserved.
//

#import "TVListChannel.h"
#import "TVListChannelCell.h"
#import "VLCMetadata.h"

static NSString *cellID=@"cellID";

@implementation TVListChannel

-(void)layoutSubviews{
    [super layoutSubviews];
    self.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.5];
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.delegate=self;
    self.dataSource=self;
    [self registerNib:[UINib nibWithNibName:@"TVListChannelCell" bundle:nil] forCellReuseIdentifier:cellID];
    
}

//-(void)setCurrentPlayChannel:(NSInteger)currentPlayChannel{
////    _currentPlayChannel=currentPlayChannel;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        //        刷新完成
//        [self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentPlayChannel inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
//    });
//}

-(void)setChannels:(NSArray *)channels{
    _channels=channels;
    [self reloadData];
    if (!channels||channels.count<=0) {
        return;
    }
//    [self layoutIfNeeded];
    [self performSelector:@selector(re) withObject:nil afterDelay:2];
    NSLog(@"----------%ld",(long)self.currentPlayChannel);
}

-(void)re{
//    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"----------%ld",(long)self.currentPlayChannel);
        //        刷新完成
        [self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentPlayChannel inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
//    });
}


- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.channels.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    if (self.currentPlayChannel==indexPath.row) {
//        return 76;
//    }
    id TvHchannel=self.channels[indexPath.row];
    if ([TvHchannel isKindOfClass:[TVHChannel class]]) {
         return 60;
    }
        return 40;
   
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    TVListChannelCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.nextChannel.text=@"";
    cell.currentPlayback.text=@"";
    id TvHchannel=self.channels[indexPath.row];
    if ([TvHchannel isKindOfClass:[TVHChannel class]]) {
        TVHChannel *channel=(TVHChannel *)TvHchannel;
        TVHEpg *currentEPG = [channel nextPrograms:3][0];
        // 日期格式化类
        NSDateFormatter *format = [[NSDateFormatter alloc] init];
        // 设置日期格式 为了转换成功
        format.dateFormat = @"HH:mm";
        NSString *startTime = [format stringFromDate:currentEPG.start];
        NSString *endTime = [format stringFromDate:currentEPG.end];
//        if (self.currentPlayChannel==indexPath.row) {
//            cell.currentPlayback.text=[NSString stringWithFormat:@"%@:%@",NSLocalizedString(@"Currently playing", @"当前正在播放"),channel.name];
//            cell.nextChannel.text=[NSString stringWithFormat:@"%@ %@",startTime.length>0?startTime:@"",currentEPG.title.length>0?currentEPG.title:@""];
//        }else{
        if (startTime.length>0) {
            cell.currentPlayback.text=[NSString stringWithFormat:@"%@-%@ %@",startTime.length>0?startTime:@"",endTime.length>0?endTime:@"",currentEPG.title.length>0?currentEPG.title:@""];
        }
        
//        }
        cell.channelName.text=channel.name;
        
        
    }else if([TvHchannel isKindOfClass:[MLFile class]]){
        MLFile *channel=(MLFile *)TvHchannel;
        NSLog(@"%@",channel.title);
        cell.channelName.text=channel.title;
    }else if ([TvHchannel isKindOfClass:[VLCMedia class]]){
        VLCMedia *channel=(VLCMedia *)TvHchannel;
        NSLog(@"%@",[[channel valueForKey:@"metaDictionary"] valueForKey:@"title"]);
        cell.channelName.text=[[channel valueForKey:@"metaDictionary"] valueForKey:@"title"];
    }
    
    
    return cell;

}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.ClockChannel) {
        self.currentPlayChannel=indexPath.row; self.ClockChannel(self.channels[indexPath.row],indexPath.row);
    }
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView;

{
    if (self.IsRoll) {
        self.IsRoll(YES);
    }
}

//开始拖拽视图

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;

{
    if (self.IsRoll) {
        self.IsRoll(YES);
    }
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;

{
    if (self.IsRoll) {
        self.IsRoll(YES);
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.IsRoll) {
        self.IsRoll(NO);
    }
}




@end
