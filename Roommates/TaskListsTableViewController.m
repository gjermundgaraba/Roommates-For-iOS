//
//  TasksTableViewController.m
//  Roommates
//
//  Created by Gjermund Bjaanes on 27/03/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import "TaskListsTableViewController.h"
#import <Parse/Parse.h>
#import "TaskListElementsTableViewController.h"
#import "SVProgressHUD.h"
#import "TaskList.h"
#import "User.h"

#define TASK_LIST_UNFINISHED_SECTION 0
#define TASK_LIST_FINISHED_SECTION 1

@interface TaskListsTableViewController () <UIAlertViewDelegate>
// Model
@property (strong, nonatomic) NSArray *unfinishedTaskLists; // of TaskList *
@property (strong, nonatomic) NSArray *finishedTaskLists; // of TaskList *
@end

@implementation TaskListsTableViewController

#pragma mark View Controller Life Cycle Methods

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // On each appear, refresh task lists
    [self refreshTaskLists];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveResetHouseholdScenesNotification:) name:@"ResetHouseholdScenes" object:nil];
}


#pragma mark setters and getters

// Safety, just in case someone tries to access before it is set
- (NSArray *)unfinishedTaskLists {
    if (!_unfinishedTaskLists) {
        _unfinishedTaskLists = @[];
    }
    return _unfinishedTaskLists;
}

// Safety, just in case someone tries to access before it is set
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
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // Add clicked
        // Get the listName from the UIAlert TextField
        NSString *listName = [alertView textFieldAtIndex:0].text;
        
        // Check validity
        if ([listName isEqualToString:@""]) {
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Could not create new task list" message:@"List Name Empty" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [errorAlert show];
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
                    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Could not create new task list" message:error.userInfo[@"error"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [errorAlert show];
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
        
        if (self.unfinishedTaskLists.count == 0 && self.finishedTaskLists.count == 0) {
            taskListsQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
        }
        else {
            taskListsQuery.cachePolicy = kPFCachePolicyNetworkOnly;
        }
        
        
        [taskListsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
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
                
                // Update UI
                [self.tableView reloadData];
            }
            [self.refreshControl endRefreshing];
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


// In a storyboard-based application, you will often want to do a little preparation before navigation
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
