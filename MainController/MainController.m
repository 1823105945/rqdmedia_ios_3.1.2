//
//  MainController.m
//  rqdMedia-iOS
//
//  Created by liu_yakai on 2019/2/25.
//  Copyright © 2019年 VideoLAN. All rights reserved.
//

#import "MainController.h"
#import "MainCollectionViewItem.h"
#import "rqdMediaAppDelegate.h"
#import "rqdMediaServerListViewController.h"
#import "rqdMediaOpenNetworkStreamViewController.h"
#import "TVHTagStoreViewController.h"
#import "TVHRecordingsViewController.h"
#import "rqdMediaAboutViewController.h"
#import "rqdMediaSettingsController.h"

static NSString *MainItemID=@"MainItemID";
@interface MainController ()<UICollectionViewDelegate,UICollectionViewDataSource>
@property (weak, nonatomic) IBOutlet UICollectionView *mainCollectionView;
@property(nonatomic,strong)NSMutableArray *controllerArray;
@property(nonatomic,strong)NSArray *listArray;
@end

@implementation MainController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"RQDTV";
    self.view.backgroundColor=[UIColor colorWithRed:31/255.0 green:31/255.0 blue:31/255.0 alpha:1];
    self.mainCollectionView.backgroundColor=[UIColor colorWithRed:31/255.0 green:31/255.0 blue:31/255.0 alpha:1];
    [self.mainCollectionView registerNib:[UINib nibWithNibName:@"MainCollectionViewItem" bundle:nil] forCellWithReuseIdentifier:MainItemID];
    rqdMediaAppDelegate *AppDelegate=(rqdMediaAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self.controllerArray addObject:AppDelegate.libraryViewController];
    [self.controllerArray addObject:[[rqdMediaServerListViewController alloc] init]];
    [self.controllerArray addObject:[[rqdMediaOpenNetworkStreamViewController alloc] initWithNibName:@"rqdMediaOpenNetworkStreamViewController" bundle:nil]];
    [self.controllerArray addObject:[[TVHTagStoreViewController alloc] init]];
    [self.controllerArray addObject:[[TVHRecordingsViewController alloc] initWithNibName:@"TVHRecordingsViewController" bundle:nil]];
    [self.controllerArray addObject:[[rqdMediaSettingsController alloc] initWithStyle:UITableViewStyleGrouped]];
    [self.controllerArray addObject:[[rqdMediaAboutViewController alloc] init]];
}

-(NSArray *)listArray{
    if (!_listArray) {
        _listArray=@[@{@"LIBRARY_ALL_FILES":@"所有文件"},@{@"LOCAL_NETWORK":@"本地网络"},@{@"NETWORK_TITLE":@"网络串流"},@{@"TVHclient":@"TV"},@{@"Recordings":@"录像"},@{@"BUTTON_SET":@"设置"},@{@"ABOUT_APP":@"关于RQD"}];
    }
    return _listArray;
}

-(NSMutableArray *)controllerArray{
    if (!_controllerArray) {
        
        _controllerArray=[NSMutableArray new];
    }
    return _controllerArray;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.listArray.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
        MainCollectionViewItem *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MainItemID forIndexPath:indexPath];
        [cell cellInit:self.listArray[indexPath.row]];
        return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return (CGSize){self.view.frame.size.width/2,120};
}


- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}


- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.f;
}

// 选中某item
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.navigationController pushViewController:self.controllerArray[indexPath.row] animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
