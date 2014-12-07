
#import "ViewExepenseTableViewController.h"
#import "InputValidation.h"
#import "SVProgressHUD.h"

#import "AddPeopleToExpenseTableViewController.h"

// Some defines for the tableview
#define INFORMATION_SECTION 0
#define INFORMATION_NAME_ROW 0
#define INFORMATION_OWED_ROW 1
#define INFORMATION_AMOUNT_ROW 2
#define INFORMATION_DETAILS_ROW 3

#define UNSETTLED_SECTION 1
#define SETTLED_SECTION 2

@interface ViewExepenseTableViewController () <UIActionSheetDelegate, UIAlertViewDelegate>

@end

@implementation ViewExepenseTableViewController

#pragma mark UIViewController Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveReloadNotification:) name:@"ExpensesDidChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveResetHouseholdScenesNotification:) name:@"ResetHouseholdScenes" object:nil];
    self.title = self.expense.name;
}

#pragma mark Methods

- (void)didReceiveResetHouseholdScenesNotification:(NSNotificationCenter *)notificationCenter {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)didReceiveReloadNotification:(NSNotificationCenter *)notificationCenter {
    [self.tableView reloadData];
}

- (IBAction)editExpense:(id)sender {
    if ([self.expense.owed.objectId isEqualToString:[User currentUser].objectId]) {
        UIActionSheet *popup =
        [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Edit Expense", nil)
                                    delegate:self
                           cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                      destructiveButtonTitle:NSLocalizedString(@"Delete Expense", nil)
                           otherButtonTitles:NSLocalizedString(@"Rename Expense", nil),
         NSLocalizedString(@"Edit Amount", nil),
         NSLocalizedString(@"Edit Details", nil),
         NSLocalizedString(@"Change People", nil),
         nil];
        [popup showInView:[UIApplication sharedApplication].keyWindow];
    }
   
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.expense) {
        return 3;
    }
    else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.expense) {
        switch (section) {
            case INFORMATION_SECTION:
                return 4;
                break;
            case UNSETTLED_SECTION:
                return self.expense.notPaidUp.count;
                break;
            case SETTLED_SECTION:
                return self.expense.paidUp.count;
                break;
            default:
                return 0;
                break;
        }
    }
    else {
        return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case INFORMATION_SECTION:
            return NSLocalizedString(@"Information about expense", nil);
            break;
        case UNSETTLED_SECTION:
            return NSLocalizedString(@"Roommates not paid up", nil);
            break;
        case SETTLED_SECTION:
            return NSLocalizedString(@"Rommates who has settled", nil);
            break;
        default:
            return @"";
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    switch (indexPath.section) {
        case INFORMATION_SECTION: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"InformationCell" forIndexPath:indexPath];
            cell.userInteractionEnabled = NO;
            switch (indexPath.row) {
                case INFORMATION_NAME_ROW:
                    cell.textLabel.text = NSLocalizedString(@"Expense", nil);
                    cell.detailTextLabel.text = self.expense.name;
                    break;
                case INFORMATION_OWED_ROW:
                    cell.textLabel.text = NSLocalizedString(@"Owed", nil);
                    cell.detailTextLabel.text = self.expense.owed.displayName;
                    break;
                case INFORMATION_AMOUNT_ROW:
                    cell.textLabel.text = NSLocalizedString(@"Total Amount", nil);
                    cell.detailTextLabel.text = [self.expense.totalAmount stringValue];
                    break;
                case INFORMATION_DETAILS_ROW:
                    cell.textLabel.text = NSLocalizedString(@"Details", nil);
                    cell.detailTextLabel.text = self.expense.details;
                    break;
            }
            break;
        }
        case UNSETTLED_SECTION: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
            
            double eachOwes = self.expense.totalAmount.doubleValue / (self.expense.notPaidUp.count + self.expense.paidUp.count);
            
            User *user = [self.expense.notPaidUp objectAtIndex:indexPath.row];
            cell.textLabel.text = user.displayName;
            cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Owes %.02f", nil), eachOwes];
            break;
        }
        case SETTLED_SECTION: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
            User *user = [self.expense.paidUp objectAtIndex:indexPath.row];
            cell.textLabel.text = user.displayName;
            cell.detailTextLabel.text = NSLocalizedString(@"Has paid up", nil);
            break;
        }
            
    }
    
    if (![self.expense.owed.objectId isEqualToString:[User currentUser].objectId]) {
        cell.userInteractionEnabled = NO;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.expense.owed.objectId isEqualToString:[User currentUser].objectId]) {
        if (indexPath.section == UNSETTLED_SECTION) {
            User *user = [self.expense.notPaidUp objectAtIndex:indexPath.row];
            NSMutableArray *newNotPaidUp = [self.expense.notPaidUp mutableCopy];
            NSMutableArray *newPaidUp = [self.expense.paidUp mutableCopy];
            
            [newNotPaidUp removeObject:user];
            [newPaidUp addObject:user];
            
            self.expense.notPaidUp = newNotPaidUp;
            self.expense.paidUp = newPaidUp;
            [self.expense saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ExpensesDidChange" object:nil];
                }
            }];
            [self.tableView reloadData];
        }
        else if (indexPath.section == SETTLED_SECTION) {
            User *user = [self.expense.paidUp objectAtIndex:indexPath.row];
            NSMutableArray *newNotPaidUp = [self.expense.notPaidUp mutableCopy];
            NSMutableArray *newPaidUp = [self.expense.paidUp mutableCopy];
            
            [newNotPaidUp addObject:user];
            [newPaidUp removeObject:user];
            
            self.expense.notPaidUp = newNotPaidUp;
            self.expense.paidUp = newPaidUp;
            [self.expense saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ExpensesDidChange" object:nil];
                }
            }];
            [self.tableView reloadData];
        }
    }
    
    
}

#pragma mark UIActionSheet Delegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: // Delete
            [self deleteExpenseDialog];
            break;
        case 1: // Rename Expense Name
            [self renameExpenseDialog];
            break;
        case 2: // Edit Amount
            [self changeAmountDialog];
            break;
        case 3: // Edit Details
            [self editDetailsDialog];
            break;
        case 4: // Add People
            [self performSegueWithIdentifier:@"addPeopleToExpenseSegue" sender:nil];
        default:
            break;
    }
}

#pragma mark ActionSheet Helper Methods

- (void)deleteExpenseDialog {
    UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to delete this expense?", nil) message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"No", nil) otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];
    deleteAlert.tag = 0;
    [deleteAlert show];
}

- (void)renameExpenseDialog {
    UIAlertView *renameAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Rename Expense", nil) message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Rename", nil), nil];
    [renameAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[renameAlert textFieldAtIndex:0] setText:self.expense.name];
    [renameAlert textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
    renameAlert.tag = 1;
    [renameAlert show];
}

- (void)changeAmountDialog {
    UIAlertView *changeAmountAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Change Total Amount", nil) message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Change Amount", nil), nil];
    [changeAmountAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[changeAmountAlert textFieldAtIndex:0] setText:[self.expense.totalAmount stringValue]];
    [[changeAmountAlert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
    changeAmountAlert.tag = 2;
    [changeAmountAlert show];
}

- (void)editDetailsDialog {
    UIAlertView *editDetailsAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Edit Details", nil) message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Change", nil), nil];
    [editDetailsAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[editDetailsAlert textFieldAtIndex:0] setText:self.expense.details];
    [editDetailsAlert textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
    editDetailsAlert.tag = 3;
    [editDetailsAlert show];
}

#pragma mark UIAlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case 0: {// deleteAlert
            if (buttonIndex == 1) { // YES, delete
                [SVProgressHUD showWithStatus:NSLocalizedString(@"Deleting expense...", nil) maskType:SVProgressHUDMaskTypeBlack];
                [self.expense deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    [SVProgressHUD dismiss];
                    if (!error) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"ExpensesDidChange" object:nil];
                        [self.navigationController popToRootViewControllerAnimated:YES];
                    } else {
                        [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
                    }
                }];
            }
            break;
        }
        case 1: {// renameAlert
            if (buttonIndex == 1) { // Change pressed
                NSString *newExpenseName = [alertView textFieldAtIndex:0].text;
                if (![newExpenseName isEqualToString:@""]) {
                    self.expense.name = newExpenseName;
                    
                    [SVProgressHUD showWithStatus:NSLocalizedString(@"Saving expense...", nil) maskType:SVProgressHUDMaskTypeBlack];
                    [self.expense saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        [SVProgressHUD dismiss];
                        if (!error) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"ExpensesDidChange" object:nil];
                            self.title = newExpenseName;
                            [self.tableView reloadData];
                        } else {
                            [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
                        }
                    }];
                } else {
                    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Expense name cannot be empty", nil)];
                }
            }
            break;
        }
        case 2: { // changeAmountAlert
            if (buttonIndex == 1) { // Change Amount pressed
                NSString *newAmount = [alertView textFieldAtIndex:0].text;
                
                if ([InputValidation validateTotalAmount:newAmount]) {
                    NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
                    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
                    NSNumber * myNumber = [numberFormatter numberFromString:newAmount];
                    
                    self.expense.totalAmount = myNumber;
                    [SVProgressHUD showWithStatus:NSLocalizedString(@"Saving expense...", nil) maskType:SVProgressHUDMaskTypeBlack];
                    [self.expense saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        [SVProgressHUD dismiss];
                        if (!error) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"ExpensesDidChange" object:nil];
                            [self.tableView reloadData];
                        } else {
                            [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
                        }
                    }];
                }
                else {
                    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Invalid Amount", nil)];
                }
            }
            break;
        }
        case 3: { // editDetailsAlert
            if (buttonIndex == 1) { // Change pressed
                NSString *newDetails = [alertView textFieldAtIndex:0].text;
                
                self.expense.details = newDetails;
                [self.expense saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    [SVProgressHUD dismiss];
                    if (!error) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"ExpensesDidChange" object:nil];
                        [self.tableView reloadData];
                    } else {
                        [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
                    }
                }];
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark Segue Method

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"addPeopleToExpenseSegue"]) {
        AddPeopleToExpenseTableViewController *targetVC = segue.destinationViewController;
        targetVC.expense = self.expense;
    }
}

@end
