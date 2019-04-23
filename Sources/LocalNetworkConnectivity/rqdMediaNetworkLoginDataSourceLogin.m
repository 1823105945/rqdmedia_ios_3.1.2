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

#import "rqdMediaNetworkLoginDataSourceLogin.h"
#import "rqdMediaNetworkLoginViewFieldCell.h"
#import "rqdMediaNetworkLoginViewButtonCell.h"

typedef NS_ENUM(NSUInteger, rqdMediaNetworkServerLoginIndex) {
    rqdMediaNetworkServerLoginIndexServer,
    rqdMediaNetworkServerLoginIndexPort,
    rqdMediaNetworkServerLoginIndexUsername,
    rqdMediaNetworkServerLoginIndexPassword,
    rqdMediaNetworkServerLoginIndexConnect,
    rqdMediaNetworkServerLoginIndexSave,

    rqdMediaNetworkServerLoginIndexCount,
    rqdMediaNetworkServerLoginIndexFieldCount = rqdMediaNetworkServerLoginIndexConnect
};

@interface rqdMediaNetworkLoginDataSourceLogin () <rqdMediaNetworkLoginViewFieldCellDelegate>
@property (nonatomic, weak) UITableView *tableView;
@end

@implementation rqdMediaNetworkLoginDataSourceLogin
@synthesize sectionIndex = _sectionIndex;

#pragma mark - API

- (void)registerCellsInTableView:(UITableView *)tableView
{
    [tableView registerClass:[rqdMediaNetworkLoginViewButtonCell class] forCellReuseIdentifier:krqdMediaNetworkLoginViewButtonCellIdentifier];
    [tableView registerClass:[rqdMediaNetworkLoginViewFieldCell class] forCellReuseIdentifier:krqdMediaNetworkLoginViewFieldCellIdentifier];
}

- (void)setLoginInformation:(rqdMediaNetworkServerLoginInformation *)loginInformation
{
    _loginInformation = loginInformation;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:self.sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - helper

- (void)configureButtonCell:(rqdMediaNetworkLoginViewButtonCell *)buttonCell forRow:(NSUInteger)row
{
    NSString *labelString = nil;
    NSUInteger additionalFieldsCount = self.loginInformation.additionalFields.count;
    NSUInteger buttonRowIndex = row-additionalFieldsCount;
    if (buttonRowIndex == rqdMediaNetworkServerLoginIndexConnect) {
            labelString = NSLocalizedString(@"BUTTON_CONNECT", nil);
    } else if (buttonRowIndex == rqdMediaNetworkServerLoginIndexSave) {
        labelString = NSLocalizedString(@"BUTTON_SAVE", nil);
    }
    buttonCell.titleString = labelString;
}

- (void)configureFieldCell:(rqdMediaNetworkLoginViewFieldCell *)fieldCell forRow:(NSUInteger)row
{
    UIKeyboardType keyboardType = UIKeyboardTypeDefault;
    BOOL secureTextEntry = NO;
    NSString *labelString = nil;
    NSString *valueString = nil;
    UIReturnKeyType returnKeyType = UIReturnKeyNext;
    switch (row) {
        case rqdMediaNetworkServerLoginIndexServer:
            keyboardType = UIKeyboardTypeURL;
            labelString = NSLocalizedString(@"SERVER", nil);
            valueString = self.loginInformation.address;
            break;
        case rqdMediaNetworkServerLoginIndexPort:
            keyboardType = UIKeyboardTypeNumberPad;
            labelString = NSLocalizedString(@"SERVER_PORT", nil);
            valueString = self.loginInformation.port.stringValue;
            break;
        case rqdMediaNetworkServerLoginIndexUsername:
            labelString = NSLocalizedString(@"USER_LABEL", nil);
            valueString = self.loginInformation.username;
            break;
        case rqdMediaNetworkServerLoginIndexPassword:
            labelString = NSLocalizedString(@"PASSWORD_LABEL", nil);
            valueString = self.loginInformation.password;
            secureTextEntry = YES;
            if (self.loginInformation.additionalFields.count == 0) {
                returnKeyType = UIReturnKeyDone;
            }
            break;
        default: {
            NSUInteger additionalFieldRow = row-rqdMediaNetworkServerLoginIndexFieldCount;
            NSArray <rqdMediaNetworkServerLoginInformationField *> *additionalFields = self.loginInformation.additionalFields;
            rqdMediaNetworkServerLoginInformationField *field = additionalFields[additionalFieldRow];
            if (field.type == rqdMediaNetworkServerLoginInformationFieldTypeNumber) {
                keyboardType = UIKeyboardTypeNumberPad;
            }
            valueString     = field.textValue;
            labelString     = field.localizedLabel;
            returnKeyType   = additionalFieldRow == additionalFields.count-1 ? UIReturnKeyDone : UIReturnKeyNext;
        }
            break;
    }

    fieldCell.placeholderString = labelString;
    UITextField *textField = fieldCell.textField;
    textField.text              = valueString;
    textField.keyboardType      = keyboardType;
    textField.secureTextEntry   = secureTextEntry;
    textField.returnKeyType     = returnKeyType;
    textField.tag               = row;
    fieldCell.delegate = self;
}

- (void)updatedStringValue:(NSString *)string forRow:(NSUInteger)row
{
    switch (row) {
        case rqdMediaNetworkServerLoginIndexServer:
            self.loginInformation.address = string;
            break;
        case rqdMediaNetworkServerLoginIndexPort:
            self.loginInformation.port = string.length > 0 ? @(string.integerValue) : nil;
            break;
        case rqdMediaNetworkServerLoginIndexUsername:
            self.loginInformation.username = string;
            break;
        case rqdMediaNetworkServerLoginIndexPassword:
            self.loginInformation.password = string;
            break;
        default: {
            NSUInteger additionalFieldRow = row-rqdMediaNetworkServerLoginIndexFieldCount;
            NSArray <rqdMediaNetworkServerLoginInformationField *> *additionalFields = self.loginInformation.additionalFields;
            rqdMediaNetworkServerLoginInformationField *field = additionalFields[additionalFieldRow];
            field.textValue = string;
        }
            break;
    }
}

- (void)makeCellFirstResponder:(UITableViewCell *)cell
{
    if ([cell isKindOfClass:[rqdMediaNetworkLoginViewFieldCell class]]) {
        [[(rqdMediaNetworkLoginViewFieldCell *)cell textField] becomeFirstResponder];
    }
}


#pragma mark - rqdMediaNetworkLoginDataSourceSection
- (void)configureWithTableView:(UITableView *)tableView
{
    [self registerCellsInTableView:tableView];
    self.tableView = tableView;
}

- (NSUInteger)numberOfRowsInTableView:(UITableView *)tableView
{
    return rqdMediaNetworkServerLoginIndexCount + self.loginInformation.additionalFields.count;
}

- (NSString *)cellIdentifierForRow:(NSUInteger)row
{
    switch (row) {
        case rqdMediaNetworkServerLoginIndexServer:
        case rqdMediaNetworkServerLoginIndexPort:
        case rqdMediaNetworkServerLoginIndexUsername:
        case rqdMediaNetworkServerLoginIndexPassword:
            return krqdMediaNetworkLoginViewFieldCellIdentifier;
        default:
            break;
    }
    NSUInteger additionalFieldsCount = self.loginInformation.additionalFields.count;
    NSUInteger buttonRowIndex = row-additionalFieldsCount;
    if (buttonRowIndex == rqdMediaNetworkServerLoginIndexConnect || buttonRowIndex == rqdMediaNetworkServerLoginIndexSave) {
        return krqdMediaNetworkLoginViewButtonCellIdentifier;
    } else {
        return krqdMediaNetworkLoginViewFieldCellIdentifier;
    }
}

- (void)configureCell:(UITableViewCell *)cell forRow:(NSUInteger)row
{
    if ([cell isKindOfClass:[rqdMediaNetworkLoginViewFieldCell class]]) {
        [self configureFieldCell:(id)cell forRow:row];
    } else if ([cell isKindOfClass:[rqdMediaNetworkLoginViewButtonCell class]]) {
        [self configureButtonCell:(id)cell forRow:row];
    } else {
        NSLog(@"%s can't configure cell: %@", __PRETTY_FUNCTION__, cell);
    }
}

- (NSUInteger)willSelectRow:(NSUInteger)row
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:self.sectionIndex]];
    if ([cell isKindOfClass:[rqdMediaNetworkLoginViewFieldCell class]]) {
        [self makeCellFirstResponder:cell];
        return NSNotFound;
    } else {
        return row;
    }
}
- (void)didSelectRow:(NSUInteger)row
{
    NSUInteger additionalFieldsCount = self.loginInformation.additionalFields.count;
    NSUInteger buttonRowIndex = row-additionalFieldsCount;
    if (buttonRowIndex == rqdMediaNetworkServerLoginIndexConnect) {
        [self.delegate connectLoginDataSource:self];
    } else if (buttonRowIndex == rqdMediaNetworkServerLoginIndexSave) {
        [self.delegate saveLoginDataSource:self];
    }
}

#pragma mark - rqdMediaNetworkLoginViewFieldCellDelegate

- (BOOL)loginViewFieldCellShouldReturn:(rqdMediaNetworkLoginViewFieldCell *)cell
{
    if (cell.textField.returnKeyType == UIReturnKeyNext) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:nextIndexPath];
        [self makeCellFirstResponder:cell];
        [self.tableView scrollToRowAtIndexPath:nextIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        return NO;
    } else {
        return YES;
    }
}

- (void)loginViewFieldCellDidEndEditing:(rqdMediaNetworkLoginViewFieldCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self updatedStringValue:cell.textField.text forRow:indexPath.row];
}

@end
