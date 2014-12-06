
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
        [[UIActionSheet alloc] initWithTitle:@"Edit Expense"
                                    delegate:self
                           cancelButtonTitle:@"Cancel"
                      destructiveButtonTitle:@"Delete Expense"
                           otherButtonTitles:@"Rename Expense",
         @"Edit Amount",
         @"Edit Details",
         @"Change People",
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
            return @"Information about expense";
            break;
        case UNSETTLED_SECTION:
            return @"Roommates not paid up";
            break;
        case SETTLED_SECTION:
            return @"Rommates who has settled";
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
                    cell.textLabel.text = @"Expense";
                    cell.detailTextLabel.text = self.expense.name;
                    break;
                case INFORMATION_OWED_ROW:
                    cell.textLabel.text = @"Owed";
                    cell.detailTextLabel.text = self.expense.owed.displayName;
                    break;
                case INFORMATION_AMOUNT_ROW:
                    cell.textLabel.text = @"Total Amount";
                    cell.detailTextLabel.text = [self.expense.totalAmount stringValue];
                    break;
                case INFORMATION_DETAILS_ROW:
                    cell.textLabel.text = @"Details";
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
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Owes %.02f", eachOwes];
            break;
        }
        case SETTLED_SECTION: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
            User *user = [self.expense.paidUp objectAtIndex:indexPath.row];
            cell.textLabel.text = user.displayName;
            cell.detailTextLabel.text = @"Has paid up";
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
            [self.expense saveEventually];
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
            [self.expense saveEventually];
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
    UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Are you sure you want to delete this expense?" message:@"" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    deleteAlert.tag = 0;
    [deleteAlert show];
}

- (void)renameExpenseDialog {
    UIAlertView *renameAlert = [[UIAlertView alloc] initWithTitle:@"Rename Expense" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Rename", nil];
    [renameAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[renameAlert textFieldAtIndex:0] setText:self.expense.name];
    [renameAlert textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
    renameAlert.tag = 1;
    [renameAlert show];
}

- (void)changeAmountDialog {
    UIAlertView *changeAmountAlert = [[UIAlertView alloc] initWithTitle:@"Change Total Amount" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Change Amount", nil];
    [changeAmountAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[changeAmountAlert textFieldAtIndex:0] setText:[self.expense.totalAmount stringValue]];
    [[changeAmountAlert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
    changeAmountAlert.tag = 2;
    [changeAmountAlert show];
}

- (void)editDetailsDialog {
    UIAlertView *editDetailsAlert = [[UIAlertView alloc] initWithTitle:@"Edit Details" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Change", nil];
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
                [self.expense deleteEventually];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ExpensesDidChange" object:nil];
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
            break;
        }
        case 1: {// renameAlert
            if (buttonIndex == 1) { // Change pressed
                NSString *newExpenseName = [alertView textFieldAtIndex:0].text;
                
                self.expense.name = newExpenseName;
                [self.expense saveEventually];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ExpensesDidChange" object:nil];
                self.title = newExpenseName;
                [self.tableView reloadData];
            }
            break;
        }
        case 2: { // changeAmountAlert
            if (buttonIndex == 1) { // Change Amount pressed
                NSString *newAmount = [alertView textFieldAtIndex:0].text;
                
                if ([InputValidation validateTotalAmount:newAmount]) {
                    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
                    [f setNumberStyle:NSNumberFormatterDecimalStyle];
                    NSNumber * myNumber = [f numberFromString:newAmount];
                    
                    self.expense.totalAmount = myNumber;
                    [self.expense saveEventually];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ExpensesDidChange" object:nil];
                    [self.tableView reloadData];
                }
                else {
                    [SVProgressHUD showErrorWithStatus:@"Invalid Amount"];
                }
            }
            break;
        }
        case 3: { // editDetailsAlert
            if (buttonIndex == 1) { // Change pressed
                NSString *newDetails = [alertView textFieldAtIndex:0].text;
                
                self.expense.details = newDetails;
                [self.expense saveEventually];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ExpensesDidChange" object:nil];
                [self.tableView reloadData];
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
