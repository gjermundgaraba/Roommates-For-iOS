
#import "ExpensesTableViewController.h"
#import "User.h"
#import "Expense.h"
#import "ViewExepenseTableViewController.h"

#define EXPENSES_UNSETTLED_SECTION 0
#define EXPENSES_SETTLED_SECTION 1

@interface ExpensesTableViewController ()
@property (strong, nonatomic) NSArray *unsettledExpenses; // of Expense *
@property (strong, nonatomic) NSArray *settledExpenses; // of Expense *
@end

@implementation ExpensesTableViewController

#pragma mark setters and getters

// Safety, just in case someone tries to access before it is set
- (NSArray *)unsettledExpenses {
    if (!_unsettledExpenses) {
        _unsettledExpenses = @[];
    }
    return _unsettledExpenses;
}

// Safety, just in case someone tries to access before it is set
- (NSArray *)settledExpenses {
    if (!_settledExpenses) {
        _settledExpenses = @[];
    }
    return _settledExpenses;
}
- (IBAction)addButtonPushed:(id)sender {
    if ([[User currentUser] isMemberOfAHousehold]) {
        [self performSegueWithIdentifier:@"addExpenseSegue" sender:nil];     
    }
   
}

- (IBAction)pull:(id)sender {
    [self refreshExpenses];
}
#pragma mark UIView Controller Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveReloadNotification:) name:@"ExpensesDidChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveResetHouseholdScenesNotification:) name:@"ResetHouseholdScenes" object:nil];
    
    [self refreshExpenses];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

#pragma mark custom methods

- (void)didReceiveResetHouseholdScenesNotification:(NSNotificationCenter *)notificationCenter {
    [self refreshExpenses];
}

// For internal changes only, no need to go to the interwebs
- (void)didReceiveReloadNotification:(NSNotificationCenter *)notificationCenter {
    [self refreshExpenses];
}

- (void)refreshExpenses {
    if ([[User currentUser] isMemberOfAHousehold]) {
        // Set up query
        PFQuery *expensesQuery = [Expense query];
        [expensesQuery whereKey:@"household" equalTo:[User currentUser].activeHousehold];
        
        [expensesQuery orderByDescending:@"updatedAt"];
        
        // Also download pointers to:
        [expensesQuery includeKey:@"owed"];
        [expensesQuery includeKey:@"notPaidUp"];
        [expensesQuery includeKey:@"paidUp"];
        
        // If no objects, get from cache first. If model populated, go straight to network
        if (self.unsettledExpenses.count == 0 && self.settledExpenses.count == 0) {
            expensesQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
        }
        else {
            expensesQuery.cachePolicy = kPFCachePolicyNetworkOnly;
        }
        
        [expensesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                // Sort expenses into unsettled and settled
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
                
                // Update UI
                [self.tableView reloadData];
                
                [self.refreshControl endRefreshing];
            }
        }];
    }
    else {
        // No user or not member of a household
        // Set empty models
        self.unsettledExpenses = [NSArray array];
        self.settledExpenses = [NSArray array];
        
        // Update UI
        [self.tableView reloadData];
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
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
        return @"Unsettled Expenses";
    }
    else if (section == EXPENSES_SETTLED_SECTION){
        return @"Settled Expenses";
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
    double whatEachOwe = expense.totalAmount.doubleValue / (expense.notPaidUp.count + expense.paidUp.count);
    
    if (indexPath.section == EXPENSES_UNSETTLED_SECTION) {
        if ([expense.owed.objectId isEqualToString:[User currentUser].objectId]) {
            // This is our own. People owe money to us
            
            double whatWeAreOwed = whatEachOwe * expense.notPaidUp.count;
            
            cell.detailTextLabel.text = [NSString stringWithFormat:@"You are owed %.02f for this expense", whatWeAreOwed];
        }
        else {
            cell.detailTextLabel.text = @"You do not owe anything for this";
            for (User *user in expense.notPaidUp) {
                if ([user.objectId isEqualToString:[User currentUser].objectId]) {
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"You owe %.02f to %@", whatEachOwe, expense.owed.displayName];
                    break;
                }
            }
        }
    }
    
    
    return cell;
}





#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
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