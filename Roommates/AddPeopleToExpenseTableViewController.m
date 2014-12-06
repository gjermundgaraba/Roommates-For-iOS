
#import "AddPeopleToExpenseTableViewController.h"
#import "User.h"
#import "SVProgressHUD.h"

@interface AddPeopleToExpenseTableViewController ()
@property (strong, nonatomic) NSArray *householdMembers;
@end

@implementation AddPeopleToExpenseTableViewController

#pragma mark setters and getters

- (NSArray *)householdMembers {
    if (!_householdMembers) {
        _householdMembers = [NSArray array];
    }
    return _householdMembers;
}

#pragma mark ViewController Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.expense && [[User currentUser] isMemberOfAHousehold]) {
        PFQuery *queryForHouseholdMembers = [User query];
        [queryForHouseholdMembers whereKey:@"activeHousehold" equalTo:[User currentUser].activeHousehold];
        
        
        [queryForHouseholdMembers findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                self.householdMembers = objects;
                [self.tableView reloadData];
                
                for (int i = 0; i < objects.count; ++i) {
                    
                    User *user = [objects objectAtIndex:i];
                    
                    if ([self notPaidUpContainsUser:user] || [self paidUpContainsUser:user]) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                    }
                }
            }
            else {
               [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
            }
        }];
        
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveResetHouseholdScenesNotification:) name:@"ResetHouseholdScenes" object:nil];
    
}


#pragma mark methods

- (void)didReceiveResetHouseholdScenesNotification:(NSNotificationCenter *)notificationCenter {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)save:(id)sender {
    NSMutableArray *tmpNotPaidUp = [self.expense.notPaidUp mutableCopy];
    NSMutableArray *tmpPaidUp = [self.expense.paidUp mutableCopy];
    BOOL changesHaveBeenMade = NO;
    
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    for (NSIndexPath *indexPath in selectedRows) {
        User *user = [self.householdMembers objectAtIndex:indexPath.row];
        if (![self notPaidUpContainsUser:user] && ![self paidUpContainsUser:user]) {
            [tmpNotPaidUp addObject:user];
            changesHaveBeenMade = YES;
        }
    }
    
    NSArray *notSelectedRows = [self indexPathsForUnselectedRows];
    for (NSIndexPath *indexPath in notSelectedRows) {
        User *user = [self.householdMembers objectAtIndex:indexPath.row];
        if ([self notPaidUpContainsUser:user]) {
            for (User *notePaidUpUser in tmpNotPaidUp) {
                if ([notePaidUpUser.objectId isEqualToString:user.objectId]) {
                    [tmpNotPaidUp removeObject:notePaidUpUser];
                    changesHaveBeenMade = YES;
                    break;
                }
            }
            
        }
        else if ([self paidUpContainsUser:user]) {
            User *user = [self.householdMembers objectAtIndex:indexPath.row];
            if ([self paidUpContainsUser:user]) {
                for (User *paidUpUser in tmpPaidUp) {
                    if ([paidUpUser.objectId isEqualToString:user.objectId]) {
                        [tmpPaidUp removeObject:paidUpUser];
                        changesHaveBeenMade = YES;
                        break;
                    }
                }
            }

        }
    }
    
    if (changesHaveBeenMade) {
        self.expense.notPaidUp = tmpNotPaidUp;
        self.expense.paidUp = tmpPaidUp;
        
        [SVProgressHUD showWithStatus:@"Saving expense" maskType:SVProgressHUDMaskTypeBlack];
        [self.expense saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [SVProgressHUD dismiss];
            if (!error) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ExpensesDidChange" object:nil];
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
            }
        }];
    }
}

- (BOOL)notPaidUpContainsUser:(User *)user {
    for (User *notPaidUpUser in self.expense.notPaidUp) {
        if ([notPaidUpUser.objectId isEqualToString:user.objectId]) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)paidUpContainsUser:(User *)user {
    for (User *paidUpUser in self.expense.paidUp) {
        if ([paidUpUser.objectId isEqualToString:user.objectId]) {
            return YES;
        }
    }
    
    return NO;
}

- (NSArray *)indexPathsForUnselectedRows {
    NSMutableArray *unselectedIndexPaths = [NSMutableArray array];
    
    NSInteger sectionCount = self.tableView.numberOfSections;
    
    for (int i = 0; i < sectionCount; i++) {
        NSInteger rowCount = [self.tableView numberOfRowsInSection:i];
        
        for (int j = 0; j < rowCount; j++) {
            [unselectedIndexPaths addObject:[NSIndexPath indexPathForRow:j inSection:i]];
        }
    }
    
    [unselectedIndexPaths removeObjectsInArray:self.tableView.indexPathsForSelectedRows];
    return unselectedIndexPaths;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.householdMembers.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"userCell" forIndexPath:indexPath];
    
    User *user = [self.householdMembers objectAtIndex:indexPath.row];
    
    cell.textLabel.text = user.displayName;
    
    // Configure the cell...
    
    return cell;
}


@end
