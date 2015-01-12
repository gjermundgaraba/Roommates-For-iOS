
#import "AddExpenseViewController.h"
#import "User.h"
#import "Expense.h"
#import "InputValidation.h"
#import "SVProgressHUD.h"

@interface AddExpenseViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (strong, nonatomic)  NSArray *householdMembers;
@property (weak, nonatomic) IBOutlet UITableView *tableView;


@property (weak, nonatomic) IBOutlet UITextField *expenseNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *expenseTotalAmountTextField;
@property (weak, nonatomic) IBOutlet UITextField *expenseDescriptionTextField;
@end

@implementation AddExpenseViewController

#pragma mark setters and getters

- (NSArray *)householdMembers {
    if (!_householdMembers) {
        _householdMembers = [NSArray array];
    }
    return _householdMembers;
}

#pragma mark UIViewController Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    PFQuery *queryForHouseholdMembers = [User query];
    [queryForHouseholdMembers whereKey:@"activeHousehold" equalTo:[User currentUser].activeHousehold];
    
    [queryForHouseholdMembers findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.householdMembers = objects;
            [self.tableView reloadData];
        } else {
            [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveResetHouseholdScenesNotification:) name:@"ResetHouseholdScenes" object:nil];
}

#pragma mark methods

- (void)didReceiveResetHouseholdScenesNotification:(NSNotificationCenter *)notificationCenter {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (IBAction)save:(id)sender {
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    
    NSString *expenseName = self.expenseNameTextField.text;
    NSString *expenseTotalAmount = self.expenseTotalAmountTextField.text;
    NSString *expenseDescription = self.expenseDescriptionTextField.text;
    
    if ([expenseName isEqualToString:@""]) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Empty expense name", nil)];
    }
    else if (![InputValidation validateTotalAmount:expenseTotalAmount]) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Invalid Amount", nil)];
    }
    else if (selectedRows.copy == 0) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"No members selected for the expense", nil)];
    }
    else {
        NSMutableArray *notPaidUp = [[NSMutableArray alloc] init];
        BOOL currentUserIsSelected = NO;
        for (NSIndexPath *indexPath in selectedRows) {
            User *user = [self.householdMembers objectAtIndex:indexPath.row];
            if ([user.objectId isEqualToString:[User currentUser].objectId]) {
                currentUserIsSelected = YES;
            }
            else {
                [notPaidUp addObject:[self.householdMembers objectAtIndex:indexPath.row]];
            } 
        }
        
        NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        NSNumber * myNumber = [numberFormatter numberFromString:expenseTotalAmount];
        
        Expense *newExpense = [Expense object];
        newExpense.name = expenseName;
        newExpense.household = [User currentUser].activeHousehold;
        newExpense.owed = [User currentUser];
        newExpense.totalAmount = myNumber;
        if (currentUserIsSelected) {
            newExpense.paidUp = @[[User currentUser]];
        }
        else {
            newExpense.paidUp = @[];
        }
        newExpense.notPaidUp = notPaidUp;
        newExpense.details = expenseDescription;
        
        PFACL *ACL = [PFACL ACL];
        [ACL setWriteAccess:YES forUser:[User currentUser]];
        [ACL setReadAccess:YES forRoleWithName:[User currentUser].householdChannel];
        newExpense.ACL = ACL;
        
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Saving Expense", nil) maskType:SVProgressHUDMaskTypeBlack];
        [newExpense saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [SVProgressHUD dismiss];
            if (!error) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ExpensesDidChange" object:nil];
                [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Expense saved!", nil)];
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
            else {
                [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
            }
        }];
    }

}


#pragma mark Table View Methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(@"Split between:", nil);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.householdMembers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"householdMemberForExpenseCell" forIndexPath:indexPath];
    
    User *user = [self.householdMembers objectAtIndex:indexPath.row];
    
    cell.textLabel.text = user.displayName;
    
    return cell;
}

#pragma mark UITextField Delegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
