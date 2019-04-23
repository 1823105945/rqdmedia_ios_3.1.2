//
//  TVHAutoRecDetailViewController.m
//  TvhClient
//
//  Created by Luis Fernandes on 3/14/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHAutoRecDetailViewController.h"
#import "TVHSettingsGenericFieldViewController.h"
#import "NSString+FileSize.h"
#import "TVHAutoRecDetailcell.h"
#import "TVHAutoRecDetailcell1.h"
#import "TVHAutoRecDetailcell2.h"
#import "TVHSingletonServer.h"

static NSString *DetailcellID=@"DetailcellID";
static NSString *DetailcellID1=@"DetailcellID1";
static NSString *DetailcellID2=@"DetailcellID2";

@interface TVHAutoRecDetailViewController () <UITextFieldDelegate>
{
    NSString *created;
    NSString *comment;
    NSString *channelName;
}
@end

@implementation TVHAutoRecDetailViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]initWithTitle:@"Save" style:(UIBarButtonItemStylePlain) target:self action:@selector(saveButton:)];
    self.tableView.tableFooterView=[UIView new];
    [self.tableView registerNib:[UINib nibWithNibName:@"TVHAutoRecDetailcell" bundle:nil] forCellReuseIdentifier:DetailcellID];
    [self.tableView registerNib:[UINib nibWithNibName:@"TVHAutoRecDetailcell1" bundle:nil] forCellReuseIdentifier:DetailcellID1];
    [self.tableView registerNib:[UINib nibWithNibName:@"TVHAutoRecDetailcell2" bundle:nil] forCellReuseIdentifier:DetailcellID2];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (textField.tag==1) {
        channelName=textField.text;
    }else if (textField.tag==9){
        created=textField.text;
    }else if (textField.tag==10){
        comment=textField.text;
    }
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

- (void)itemSetEnable:(UISwitch*)switchField {
    [self.item setEnabled:switchField.on];
    [self.item updateValue:[NSNumber numberWithBool:switchField.on] forKey:@"enabled"];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 11;
}

#pragma mark - Table view data source
 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
 {
     if (indexPath.row==0) {
         TVHAutoRecDetailcell *cell = [tableView dequeueReusableCellWithIdentifier:DetailcellID forIndexPath:indexPath];
         __weak typeof(self)SelfWeek=self;
         cell.Clock = ^(id send) {
             [SelfWeek itemSetEnable:send];
         };
         cell.titleLable.text=[self.item title];
         cell.cellSwitch.on=[self.item enabled];
         return cell;
     }else if (indexPath.row==1||indexPath.row==9||indexPath.row==10){
         TVHAutoRecDetailcell2 *cell = [tableView dequeueReusableCellWithIdentifier:DetailcellID2 forIndexPath:indexPath];
         cell.cellTextField.delegate=self;
         cell.cellTextField.tag=indexPath.row;
         if (indexPath.row==1) {
            cell.titleLable.text=@"Title";
             cell.cellTextField.text=[self.item title];
         }else if (indexPath.row==9){
            cell.titleLable.text=@"Created by";
            cell.cellTextField.text=[self.item creator];
         }else if (indexPath.row==10){
            cell.titleLable.text=@"Comment";
            cell.cellTextField.text=[self.item comment];
         }
         return cell;
     }else{
         TVHAutoRecDetailcell1 *cell = [tableView dequeueReusableCellWithIdentifier:DetailcellID1 forIndexPath:indexPath];
         if (indexPath.row==2) {
             cell.detailLable.text=[self.item.channelObject name];
             cell.titleLable.text=@"Channel";
         }else if (indexPath.row==3){
             cell.detailLable.text=[self.item tag];
             cell.titleLable.text=@"Tag";
         }else if (indexPath.row==4){
             cell.detailLable.text=[self.item genre];
             cell.titleLable.text=@"Genre";
         }else if (indexPath.row==5){
             cell.detailLable.text=[NSString stringOfWeekdaysLocalizedFromArray:self.item.weekdays joinedByString:@","];
             cell.titleLable.text=@"Weekdays";
         }else if (indexPath.row==6){
             cell.detailLable.text=self.item.stringFromAproxTime;
             cell.titleLable.text=@"Start around";
         }else if (indexPath.row==7){
             cell.detailLable.text=[self.item pri];
             cell.titleLable.text=@"Priority";
         }else if (indexPath.row==8){
             cell.detailLable.text=[self.item config_name];
             cell.titleLable.text=@"DVR Config";
         }
         return cell;
     }
 
 return nil;
 }

#pragma mark - Table view delegate

- (NSArray*)arrayOfWeekdaysLocalized
{
    NSMutableArray *localizedStringOfweekday = [[[[NSDateFormatter alloc] init] shortWeekdaySymbols] mutableCopy];
    // hack for making 1==monday 7==sunday
    [localizedStringOfweekday addObject:[localizedStringOfweekday objectAtIndex:0]];
    [localizedStringOfweekday removeObjectAtIndex:0];
    return [localizedStringOfweekday copy];
}

- (NSArray*)arrayOfDayTimes
{
    NSMutableArray *days = [[NSMutableArray alloc] init];
    for ( int i = 0 ; i < 144; i++ ) {
        [days addObject:[TVHAutoRecItem stringFromMinutes:i*10] ];
    }
    return days;
}

- (NSArray*)arrayOfImportance
{
    return @[@"important", @"high", @"normal", @"low", @"unimportant"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.row > 1 && indexPath.row < 9 && indexPath.row != 4 && indexPath.row != 8 && indexPath.row != 5 ) {
        [self prepare:indexPath];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepare:(NSIndexPath *)path {
        TVHSettingsGenericFieldViewController *vc=[[TVHSettingsGenericFieldViewController alloc]init];
        if ( path.section == 0 && path.row == 2 ) {
            id <TVHChannelStore> channelStore = [[TVHSingletonServer sharedServerInstance] channelStore];
            NSArray *objectChannelList = [channelStore channels];
            NSMutableArray *list = [[NSMutableArray alloc] init];
            [objectChannelList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [list addObject:[obj name]];
            }];
            [vc setTitle:NSLocalizedString(@"Channel", nil)];
            [vc setSectionHeader:NSLocalizedString(@"Channel", nil)];
            [vc setOptions:list];
            [vc setSelectedOption:[list indexOfObject:[self.item.channelObject name]]];
            [vc setResponseBack:^(NSInteger order) {
                NSString *text = [list objectAtIndex:order];
                TVHChannel *channel = [[self.item.tvhServer channelStore] channelWithName:text];
                if ( channel.uuid ) {
                    [self.item updateValue:channel.channelIdKey forKey:@"channel"];
                    [self.item setChannel:channel.channelIdKey];
                } else {
                    [self.item updateValue:channel.name forKey:@"channel"];
                    [self.item setChannel:channel.name];
                }
            }];
            
        }else if ( path.section == 0 && path.row == 3 ) {
            id <TVHTagStore> tagStore = [[TVHSingletonServer sharedServerInstance] tagStore];
            NSArray *objectTagList = [tagStore tags];
            NSMutableArray *list = [[NSMutableArray alloc] init];
            [objectTagList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [list addObject:[obj name]];
            }];
            
            [vc setTitle:NSLocalizedString(@"Tag", nil)];
            [vc setSectionHeader:NSLocalizedString(@"Tag", nil)];
            [vc setOptions:list];
            [vc setSelectedOption:[list indexOfObject:[self.item tag]]];
            [vc setResponseBack:^(NSInteger order) {
                NSString *text = [list objectAtIndex:order];
                [self.item updateValue:text forKey:@"tag"];
                [self.item setTag:text];
            }];
        }else if ( path.section == 0 && path.row == 6 ) {
            NSArray *list = [self arrayOfDayTimes];
            [vc setTitle:NSLocalizedString(@"Start Around", @"Auto rec edit - start around")];
            [vc setSectionHeader:NSLocalizedString(@"Start Around", @"Auto rec edit - start around")];
            [vc setOptions:list];
            [vc setSelectedOption:self.item.approx_time / 10];
            [vc setResponseBack:^(NSInteger order) {
                [self.item updateValue:[NSNumber numberWithInt:(int)order*10] forKey:@"approx_time"];
                [self.item setApprox_time:order*10];
            }];
        }else if ( path.section == 0 && path.row == 7 ) {
            NSArray *list = [self arrayOfImportance];
            [vc setTitle:NSLocalizedString(@"Priority", nil)];
            [vc setSectionHeader:NSLocalizedString(@"Priority", nil)];
            [vc setOptions:list];
            [vc setSelectedOption:[list indexOfObject:[self.item pri]]];
            [vc setResponseBack:^(NSInteger order) {
                NSString *text = [list objectAtIndex:order];
                [self.item updateValue:text forKey:@"pri"];
                [self.item setPri:text];
            }];
        }
        
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)setItem:(TVHAutoRecItem *)item {
    _item = item;
    [_item setTvhServer:[TVHSingletonServer sharedServerInstance]];
}

- (IBAction)saveButton:(id)sender {
    [self.view.window endEditing: YES];
    // check for the 3 titles
    if ( ! [channelName isEqualToString:[self.item title]] ) {
        [self.item updateValue:channelName forKey:@"title"];
    }
    if ( ! [created isEqualToString:[self.item comment]] ) {
        [self.item updateValue:created forKey:@"comment"];
    }
    if ( ! [comment isEqualToString:[self.item creator]] ) {
        [self.item updateValue:comment forKey:@"creator"];
    }
    [self.item updateAutoRec];
    [self.navigationController popViewControllerAnimated:YES];
}
@end
