
#import "ExpensesTableViewController.h"
#import "User.h"
#import "Expense.h"
#import "ViewExepenseTableViewController.h"
#import "SVProgressHUD.h"

#define EXPENSES_UNSETTLED_SECTION 0
#define EXPENSES_SETTLED_SECTION 1

@interface ExpensesTableViewController ()
@property (strong, nonatomic) NSArray *unsettledExpenses; // of Expense *
@property (strong, nonatomic) NSArray *settledExpenses; // of Expense *
@end

@implementation ExpensesTableViewController

#pragma mark setters and getters

- (NSArray *)unsettledExpenses {
    if (!_unsettledExpenses) {
        _unsettledExpenses = @[];
    }
    return _unsettledExpenses;
}

- (NSArray *)settledExpenses {
    if (!_settledExpenses) {
        _settledExpenses = @[];
    }
    return _settledExpenses;
}

- (IBAction)pull:(id)sender {
    [self refreshExpenses];
}
#pragma mark UIView Controller Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateUserInteractionEnabled];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveReloadNotification:) name:@"ExpensesDidChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveResetHouseholdScenesNotification:) name:@"ResetHouseholdScenes" object:nil];
    
    [self refreshExpenses];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

#pragma mark custom methods

- (void)updateUserInteractionEnabled {
    if ([[User currentUser] isMemberOfAHousehold]) {
        self.tableView.userInteractionEnabled = YES;
    } else {
        self.tableView.userInteractionEnabled = NO;
    }
}

- (void)didReceiveResetHouseholdScenesNotification:(NSNotificationCenter *)notificationCenter {
    [self updateUserInteractionEnabled];
    [self refreshExpenses];
}

- (void)didReceiveReloadNotification:(NSNotificationCenter *)notificationCenter {
    [self refreshExpenses];
}

- (void)setNoExpenses {
    self.unsettledExpenses = [NSArray array];
    self.settledExpenses = [NSArray array];
    
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (PFQuery *)getExpenseQuery {
    PFQuery *expensesQuery = [Expense query];
    [expensesQuery whereKey:@"household" equalTo:[User currentUser].activeHousehold];
    [expensesQuery orderByDescending:@"updatedAt"];
    [expensesQuery includeKey:@"owed"];
    [expensesQuery includeKey:@"notPaidUp"];
    [expensesQuery includeKey:@"paidUp"];
    
    if (self.unsettledExpenses.count == 0 && self.settledExpenses.count == 0 && [expensesQuery hasCachedResult]) {
        expensesQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    else {
        expensesQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    }
    return expensesQuery;
}

- (void)updateExpensesFromQuery:(NSArray *)objects error:(NSError *)error {
    if (!error) {
        NSMutableArray *tmp_unsettledExpenses = [objects mutableCopy];
        NSMutableArray *tmp_settledExpenses = [[NSMutableArray alloc] init];
        
        for (Expense *expense in objects) {
            if (expense.notPaidUp.count == 0) {
                [tmp_settledExpenses addObject:expense];
                [tmp_unsettledExpenses removeObject:expense];
            }
        }
        
        self.unsettledExpenses = tmp_unsettledExpenses;
        self.settledExpenses = tmp_settledExpenses;
        
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    } else {
        [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
    }
}

- (void)queryExpenses {
    PFQuery *expensesQuery;
    expensesQuery = [self getExpenseQuery];
    
    [expensesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [self updateExpensesFromQuery:objects error:error];
    }];
}

- (void)refreshExpenses {
    if ([[User currentUser] isMemberOfAHousehold]) {
        [self queryExpenses];
    }
    else {
        [self setNoExpenses];
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == EXPENSES_UNSETTLED_SECTION) {
        return self.unsettledExpenses.count;
    }
    else if (section == EXPENSES_SETTLED_SECTION) {
        return self.settledExpenses.count;
    }
    else {
        return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == EXPENSES_UNSETTLED_SECTION) {
        return NSLocalizedString(@"Unsettled Expenses", nil);
    }
    else if (section == EXPENSES_SETTLED_SECTION){
        return NSLocalizedString(@"Settled Expenses", nil);
    }
    else {
        return @"";
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"expenseCell" forIndexPath:indexPath];
    
    Expense *expense;
    if (indexPath.section == EXPENSES_UNSETTLED_SECTION) {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.textColor = [UIColor blackColor];
        
        expense = [self.unsettledExpenses objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == EXPENSES_SETTLED_SECTION) {
        cell.textLabel.textColor = [UIColor lightGrayColor];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        
        expense = [self.settledExpenses objectAtIndex:indexPath.row];
    }
    else {
        return cell;
    }
    
    cell.textLabel.text = expense.name;
    cell.detailTextLabel.text = @"";
    NSNumber *whatEachOwe = [NSNumber numberWithDouble:expense.totalAmount.doubleValue / (expense.notPaidUp.count + expense.paidUp.count)];
    
    if (indexPath.section == EXPENSES_UNSETTLED_SECTION) {
        if ([expense.owed.objectId isEqualToString:[User currentUser].objectId]) {            
            NSNumber *whatWeAreOwed = [NSNumber numberWithDouble:whatEachOwe.doubleValue * expense.notPaidUp.count];
            
            cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"You are owed %@ for this expense", nil), whatWeAreOwed.stringValue];
        }
        else {
            cell.detailTextLabel.text = NSLocalizedString(@"You do not owe anything for this", nil);
            for (User *user in expense.notPaidUp) {
                if ([user.objectId isEqualToString:[User currentUser].objectId]) {
                    cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"You owe %@ to %@", nil), whatEachOwe, expense.owed.displayName];
                    break;
                }
            }
        }
    }
    
    
    return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"viewExpenseSegue"]) {
        ViewExepenseTableViewController *targetVC = segue.destinationViewController;
        Expense *clickedExpense;
        
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath.section == EXPENSES_UNSETTLED_SECTION) {
            clickedExpense = [self.unsettledExpenses objectAtIndex:indexPath.row];
        }
        else if (indexPath.section == EXPENSES_SETTLED_SECTION) {
            clickedExpense = [self.settledExpenses objectAtIndex:indexPath.row];
        }
        
        targetVC.expense = clickedExpense;
    }
}


@end
