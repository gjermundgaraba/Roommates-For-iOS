//
//  AddExpenseViewController.m
//  Roommates
//
//  Created by Gjermund Bjaanes on 25/04/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

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
            
            // Select ourselves:
            for (int i = 0; i < objects.count; ++i) {
                User *user = [objects objectAtIndex:i];
                if ([user.objectId isEqualToString:[User currentUser].objectId]) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                    break;
                }
            }
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
        UIAlertView *emptyNameAlert = [[UIAlertView alloc] initWithTitle:@"Could not create expense" message:@"Empty expense name" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [emptyNameAlert show];
    }
    else if (![InputValidation validateTotalAmount:expenseTotalAmount]) {
        UIAlertView *invalidAmountAlert = [[UIAlertView alloc] initWithTitle:@"Could not create expense" message:@"Invalid Amount" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [invalidAmountAlert show];
    }
    else if (selectedRows.copy == 0) {
        UIAlertView *noMemberSelectedAlert = [[UIAlertView alloc] initWithTitle:@"Could not create expense" message:@"No members selcted for the expense" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [noMemberSelectedAlert show];
    }
    else {
        // Its all OK!
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
        
        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        NSNumber * myNumber = [f numberFromString:expenseTotalAmount];
        
        // Time to save our expense!
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
        
        // Set up ACL
        PFACL *ACL = [PFACL ACL];
        [ACL setWriteAccess:YES forUser:[User currentUser]];
        [ACL setReadAccess:YES forRoleWithName:[User currentUser].householdChannel];
        
        newExpense.ACL = ACL;
        
        [SVProgressHUD showWithStatus:@"Saving Expense" maskType:SVProgressHUDMaskTypeBlack];
        [newExpense saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [SVProgressHUD dismiss];
            if (!error) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ExpensesDidChange" object:nil];
                [SVProgressHUD showSuccessWithStatus:@"Expense saved!"];
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
            else {
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Could not save expense" message:error.userInfo[@"error"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [errorAlert show];
            }
        }];
    }

}


#pragma mark Table View Methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Roommates who owe for this expense";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
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
