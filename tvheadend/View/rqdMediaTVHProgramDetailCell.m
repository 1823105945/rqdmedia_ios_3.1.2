//
//  rqdMediaTVHProgramDetailCell.m
//  rqdMedia-iOS
//
//  Created by liu_yakai on 2019/1/17.
//  Copyright © 2019年 VideoLAN. All rights reserved.
//

#import "rqdMediaTVHProgramDetailCell.h"

@implementation rqdMediaTVHProgramDetailCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}
- (IBAction)recordClock:(id)sender {
    if (self.Clock) {
        self.Clock(sender);
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
