//
//  MainCollectionViewItem.h
//  rqdMedia-iOS
//
//  Created by liu_yakai on 2019/2/25.
//  Copyright © 2019年 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainCollectionViewItem : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *itemImage;
@property (weak, nonatomic) IBOutlet UILabel *cellText;
-(void)cellInit:(NSDictionary *)dic;
@end
