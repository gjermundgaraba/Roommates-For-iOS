
#import "TaskListsTableViewController.h"
#import <Parse/Parse.h>
#import "TaskListElementsTableViewController.h"
#import "SVProgressHUD.h"
#import "TaskList.h"
#import "User.h"

#define TASK_LIST_UNFINISHED_SECTION 0
#define TASK_LIST_FINISHED_SECTION 1

@interface TaskListsTableViewController () <UIAlertViewDelegate>
@property (strong, nonatomic) NSArray *unfinishedTaskLists; // of TaskList *
@property (strong, nonatomic) NSArray *finishedTaskLists; // of TaskList *
@end

@implementation TaskListsTableViewController

#pragma mark View Controller Life Cycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveResetHouseholdScenesNotification:) name:@"ResetHouseholdScenes" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveTaskListChangedNotification:) name:@"TaskListChanged" object:nil];
    [self refreshTaskLists];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}


#pragma mark setters and getters

- (NSArray *)unfinishedTaskLists {
    if (!_unfinishedTaskLists) {
        _unfinishedTaskLists = @[];
    }
    return _unfinishedTaskLists;
}

- (NSArray *)finishedTaskLists {
    if (!_finishedTaskLists) {
        _finishedTaskLists = @[];
    }
    return _finishedTaskLists;
}


#pragma mark Methods

- (void)didReceiveResetHouseholdScenesNotification:(NSNotificationCenter *)notificationCenter {
    [self refreshTaskLists];
}

- (void)didReceiveTaskListChangedNotification:(NSNotificationCenter *)notificationCenter {
    [self refreshTaskLists];
}

- (IBAction)pullToRefresh:(id)sender {
    [self refreshTaskLists];
}


- (IBAction)addTaskListButtonPressed:(id)sender {
    if ([[User currentUser] isMemberOfAHousehold]) {
        UIAlertView *addTaskListAlert = [[UIAlertView alloc] initWithTitle:@"Add New Task List"
                                                                   message:@""
                                                                  delegate:self
                                                         cancelButtonTitle:@"Cancel"
                                                         otherButtonTitles:@"Add", nil];
        addTaskListAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [addTaskListAlert textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
        [addTaskListAlert show];
    } else {
        [SVProgressHUD showErrorWithStatus:@"Not member of a household! Go to Me->Household Settings."];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // Add clicked
        NSString *listName = [alertView textFieldAtIndex:0].text;
        
        if ([listName isEqualToString:@""]) {
            [SVProgressHUD showErrorWithStatus:@"List Name is Empty"];
        } else if ([User currentUser] && [User currentUser].isMemberOfAHousehold) {
            TaskList *newTaskList = (TaskList *)[PFObject objectWithClassName:@"TaskList"];
            newTaskList.listName  = listName;
            newTaskList.done = NO;
            newTaskList.createdBy = [User currentUser];
            newTaskList.household = [User currentUser].activeHousehold;
            
            [SVProgressHUD showWithStatus:@"Creating new Task List" maskType:SVProgressHUDMaskTypeBlack];
            [newTaskList saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [SVProgressHUD dismiss];
                if (!error) {
                    [SVProgressHUD showSuccessWithStatus:@"New Task List Created!"];
                    [self refreshTaskLists];
                }
                else {
                    [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
                }
            }];
        }
    }
}

- (void)refreshTaskLists {
    if ([[User currentUser] isMemberOfAHousehold]) {
        PFQuery *taskListsQuery = [TaskList query];
        [taskListsQuery whereKey:@"household" equalTo:[User currentUser].activeHousehold];
        [taskListsQuery includeKey:@"createdBy"];
        [taskListsQuery includeKey:@"updatedBy"];
        [taskListsQuery orderByDescending:@"updatedAt"];
        
        if (self.unfinishedTaskLists.count == 0 && self.finishedTaskLists.count == 0 && [taskListsQuery hasCachedResult]) {
            taskListsQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
        }
        else {
            taskListsQuery.cachePolicy = kPFCachePolicyNetworkOnly;
        }
        
        
        [taskListsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            [self.refreshControl endRefreshing];
            if (!error) {
                NSMutableArray *unfinishedTaskLists = [objects mutableCopy];
                NSMutableArray *finishedTaskList = [[NSMutableArray alloc] init];
                
                for (TaskList *taskList in objects) {
                    if (taskList.done) {
                        [finishedTaskList addObject:taskList];
                        [unfinishedTaskLists removeObject:taskList];
                    }
                }
                
                self.unfinishedTaskLists = unfinishedTaskLists;
                self.finishedTaskLists = finishedTaskList;
                
                [self.tableView reloadData];
            } else {
                [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
            }
            
        }];
    }
    else {
        [self.refreshControl endRefreshing];
        self.unfinishedTaskLists = [NSArray array];
        self.finishedTaskLists = [NSArray array];
        [self.tableView reloadData];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == TASK_LIST_UNFINISHED_SECTION) {
        return self.unfinishedTaskLists.count;
    }
    else if (section == TASK_LIST_FINISHED_SECTION) {
        return self.finishedTaskLists.count;
    }
    else {
        return 0;
    }
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == TASK_LIST_UNFINISHED_SECTION) {
        return @"Tasks";
    }
    else if (section == TASK_LIST_FINISHED_SECTION){
        return @"Finished Tasks";
    }
    else {
        return @"";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = cell = [tableView dequeueReusableCellWithIdentifier:@"taskListCell"
                                                                   forIndexPath:indexPath];
    TaskList *taskList;
    
    if (indexPath.section == TASK_LIST_UNFINISHED_SECTION) {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.textColor = [UIColor blackColor];
        
        taskList = [self.unfinishedTaskLists objectAtIndex:indexPath.row];
        
    }
    else if (indexPath.section == TASK_LIST_FINISHED_SECTION) {
        cell.textLabel.textColor = [UIColor lightGrayColor];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        
        taskList = [self.finishedTaskLists objectAtIndex:indexPath.row];
    }
    else {
        return cell;
    }
    
    
    User *createdBy = taskList.createdBy;
    
    cell.textLabel.text = taskList.listName;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Created by %@", createdBy.displayName];
    return cell;
}


#pragma mark - Navigation


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"viewTaskListElementsSegue"]) {
        if ([sender isKindOfClass:[UITableViewCell class]] &&
            [segue.destinationViewController isKindOfClass:[TaskListElementsTableViewController class]])
        {
            UITableViewCell *cell = sender;
            TaskListElementsTableViewController *targetVC = segue.destinationViewController;
            
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            TaskList *taskList;
            
            if (indexPath.section == TASK_LIST_UNFINISHED_SECTION) {
                taskList = [self.unfinishedTaskLists objectAtIndex:indexPath.row];
            }
            else if (indexPath.section == TASK_LIST_FINISHED_SECTION) {
                taskList = [self.finishedTaskLists objectAtIndex:indexPath.row];
            }
            
            targetVC.taskList = taskList;
        }
    }
}


@end
