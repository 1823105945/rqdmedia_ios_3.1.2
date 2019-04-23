//
//  MainCollectionViewItem.m
//  rqdMedia-iOS
//
//  Created by liu_yakai on 2019/2/25.
//  Copyright © 2019年 VideoLAN. All rights reserved.
//

#import "MainCollectionViewItem.h"

@implementation MainCollectionViewItem

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}
-(void)cellInit:(NSDictionary *)dic{
    self.itemImage.image=[UIImage imageNamed:dic.allValues[0]];
    self.cellText.text=NSLocalizedString(dic.allKeys[0], nil);
}
@end
