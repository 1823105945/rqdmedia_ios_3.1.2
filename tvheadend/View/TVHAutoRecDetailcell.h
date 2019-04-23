//
//  TVHAutoRecDetailcell.h
//  rqdMedia-iOS
//
//  Created by liu_yakai on 2019/1/18.
//  Copyright © 2019年 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TVHAutoRecDetailcell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLable;
@property (weak, nonatomic) IBOutlet UISwitch *cellSwitch;
@property(nonatomic,copy)void (^ Clock)(id send);
@end
