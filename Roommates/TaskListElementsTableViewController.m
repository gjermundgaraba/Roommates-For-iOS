
#import "TaskListElementsTableViewController.h"
#import "EditTaskListElementViewController.h"
#import "TaskListElement.h"

#import "SVProgressHUD.h"

#define unfinishedSectionNumber 0
#define finishedSectionNumber 1

@interface TaskListElementsTableViewController () <UIAlertViewDelegate, UITextFieldDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) NSArray *finishedTaskListElements; // of TaskListElement *
@property (strong, nonatomic) NSArray *unfinishedTaskListElements; // of TaskListElement *
@property (weak, nonatomic) IBOutlet UITextField *addItemTextField;
@end

@implementation TaskListElementsTableViewController

#pragma mark getters and setters

// Safety, just in case someone tries to use it before they have been fetched
- (NSArray *)finishedTaskListElements {
    if (!_finishedTaskListElements) {
        _finishedTaskListElements = [[NSArray alloc] init];
    }
    return _finishedTaskListElements;
}

// Safety, just in case someone tries to use it before they have been fetched
- (NSArray *)unfinishedTaskListElements {
    if (!_unfinishedTaskListElements) {
        _unfinishedTaskListElements = [[NSArray alloc] init];
    }
    return _unfinishedTaskListElements;
}

// Overwrites the taskList setter
// Refreshed the table view after set
// Sets title of scene also
- (void)setTaskList:(TaskList *)taskList {
    _taskList = taskList;
    
    [self refreshTaskListElements];
    
    self.title = taskList.listName;
}

#pragma mark View Controller Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Changes height of the add item text field
    CGRect frameRect = self.addItemTextField.frame;
    frameRect.size.height = 44;
    self.addItemTextField.frame = frameRect;
    
    // Sets up a toolbar to show over the keyboard
    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
    numberToolbar.barStyle = UIBarStyleDefault;
    numberToolbar.items = [NSArray arrayWithObjects:
                           [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithAdding)],
                           nil];
    [numberToolbar sizeToFit];
    self.addItemTextField.inputAccessoryView = numberToolbar;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveResetHouseholdScenesNotification:) name:@"ResetHouseholdScenes" object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![[User currentUser] isMemberOfAHousehold]) {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
}

#pragma mark Methods

- (void)didReceiveResetHouseholdScenesNotification:(NSNotificationCenter *)notificationCenter {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (IBAction)pullToRefresh:(id)sender {
    [self refreshTaskListElements];
}

- (IBAction)editList:(id)sender {
    //sets up uiactionsheet
    NSString *toggleTitle;
    if (self.taskList.done) {
        toggleTitle = @"Mark as unfinished";
    }
    else {
        toggleTitle = @"Mark as finished";
    }
    UIActionSheet *popup =
            [[UIActionSheet alloc] initWithTitle:@"Edit List"
                                        delegate:self
                               cancelButtonTitle:@"Cancel"
                          destructiveButtonTitle:@"Delete Task List"
                               otherButtonTitles:@"Rename Task List",
                                                 toggleTitle,
                                                 nil];
    [popup showInView:[UIApplication sharedApplication].keyWindow];
}

// Will be called from the toolbar to signal that adding is done
// Removes keyboard from screen
- (void)doneWithAdding {
    [self.addItemTextField resignFirstResponder];
}

// Gets task lists
- (void)refreshTaskListElements {
    if ([[User currentUser] isMemberOfAHousehold]) {
        PFQuery *taskListElementsQuery = [TaskListElement query];
        [taskListElementsQuery whereKey:@"taskList" equalTo:self.taskList];
        [taskListElementsQuery includeKey:@"createdBy"];
        [taskListElementsQuery includeKey:@"updatedBy"];
        [taskListElementsQuery includeKey:@"finishedBy"];
        [taskListElementsQuery orderByDescending:@"updatedAt"];
        
        if (self.unfinishedTaskListElements.count == 0 && self.finishedTaskListElements == 0) {
            taskListElementsQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
        }
        else {
            taskListElementsQuery.cachePolicy = kPFCachePolicyNetworkOnly;
        }
        
        
        [taskListElementsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                NSMutableArray *unfinishedTaskListElements = [objects mutableCopy];
                NSMutableArray *finishedTaskListElements = [[NSMutableArray alloc] init];
                
                for (TaskListElement *taskList in objects) {
                    if (taskList.finishedBy) {
                        [finishedTaskListElements addObject:taskList];
                        [unfinishedTaskListElements removeObject:taskList];
                    }
                }
                
                self.unfinishedTaskListElements = unfinishedTaskListElements;
                self.finishedTaskListElements = finishedTaskListElements;
                [self.tableView reloadData];
            }
            [self.refreshControl endRefreshing];
        }];
    }
    else {
        [self.refreshControl endRefreshing];
        self.unfinishedTaskListElements = [NSArray array];
        self.finishedTaskListElements = [NSArray array];
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
    if (section == unfinishedSectionNumber) {
        return self.unfinishedTaskListElements.count;
    }
    else if (section == finishedSectionNumber) {
        return self.finishedTaskListElements.count;
    }
    else {
        return 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"taskListElementCell" forIndexPath:indexPath];
    
    TaskListElement *taskListElement;
    if (indexPath.section == unfinishedSectionNumber) {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.textColor = [UIColor blackColor];
        
        taskListElement = [self.unfinishedTaskListElements objectAtIndex:indexPath.row];
        User *createdBy = taskListElement.createdBy;
        cell.detailTextLabel.text =
                [NSString stringWithFormat:@"Added by %@", createdBy.displayName];
    }
    else if (indexPath.section == finishedSectionNumber) {
        cell.textLabel.textColor = [UIColor lightGrayColor];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        
        taskListElement = [self.finishedTaskListElements objectAtIndex:indexPath.row];
        User *finishedBy = taskListElement.finishedBy;
        cell.detailTextLabel.text =
                [NSString stringWithFormat:@"Finished by %@", finishedBy.displayName];
    }
    
    
    cell.textLabel.text = taskListElement.elementName;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Marking an element as finished or unmarking an element
    // Basicly toggeling
    if (indexPath.section == unfinishedSectionNumber) {
        TaskListElement *taskListElement = [self.unfinishedTaskListElements objectAtIndex:indexPath.row];
        taskListElement.finishedBy = [User currentUser];
        
        
        
        //TODO: COMMENT THIS
        NSMutableArray *unfinishedTmpArray = [self.unfinishedTaskListElements mutableCopy];
        [unfinishedTmpArray removeObject:taskListElement];
        
        NSMutableArray *finishedTmpArray = [[NSMutableArray alloc] init];
        [finishedTmpArray addObject:taskListElement];
        [finishedTmpArray addObjectsFromArray:self.finishedTaskListElements];
        
        self.unfinishedTaskListElements = unfinishedTmpArray;
        self.finishedTaskListElements = finishedTmpArray;
        [self.tableView reloadData];
        
        
        
        [taskListElement saveEventually];
//        [taskListElement saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//            if (!error) {
//                [self refreshTaskListElements];
//            }
//        }];
    }
    else if (indexPath.section == finishedSectionNumber) {
        TaskListElement *taskListElement = [self.finishedTaskListElements objectAtIndex:indexPath.row];
        [taskListElement removeObjectForKey:@"finishedBy"];
        
        //TODO: COMMENT THIS finishedTmpArray
        NSMutableArray *finishedTmpArray = [self.finishedTaskListElements mutableCopy];
        [finishedTmpArray removeObject:taskListElement];
        
        NSMutableArray *unfinishedTmpArray = [[NSMutableArray alloc] init];
        [unfinishedTmpArray addObject:taskListElement];
        [unfinishedTmpArray addObjectsFromArray:self.unfinishedTaskListElements];
        
        self.unfinishedTaskListElements = unfinishedTmpArray;
        self.finishedTaskListElements = finishedTmpArray;
        [self.tableView reloadData];

        [taskListElement saveEventually];
//        [taskListElement saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//            if (!error) {
//                [self refreshTaskListElements];
//            }
//        }];

    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == unfinishedSectionNumber) {
        return @"";
    }
    else if (section == finishedSectionNumber) {
        return @"Done";
    }
    
    return @"";
}


#pragma mark UITextField Delegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *elementName = textField.text;
    
    if (![elementName isEqualToString:@""]) {
        if ([User currentUser] && [User currentUser].activeHousehold && self.taskList) {
            TaskListElement *newTaskListElement = [TaskListElement object];
            newTaskListElement.elementName = elementName;
            newTaskListElement.taskList    = self.taskList;
            newTaskListElement.createdBy   = [User currentUser];
            
            [SVProgressHUD showWithStatus:@"Adding New Task List Element" maskType:SVProgressHUDMaskTypeBlack];
            [newTaskListElement saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [SVProgressHUD dismiss];
                if (!error) {
                    [self refreshTaskListElements];
                }
                else {
                    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Could not create new task list element" message:error.userInfo[@"error"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [errorAlert show];
                }
            }];
        }
    }

    textField.text = @"";
    //[textField resignFirstResponder];
    return NO;
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"editTaskListElementSegue"]) {
        if ([sender isKindOfClass:[UITableViewCell class]] &&
            [segue.destinationViewController isKindOfClass:[EditTaskListElementViewController class]])
        {
            UITableViewCell *cell = sender;
            EditTaskListElementViewController *targetVC = segue.destinationViewController;
            
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            TaskListElement *taskListElement;
            
            if (indexPath.section == 0) {
                taskListElement = [self.unfinishedTaskListElements objectAtIndex:indexPath.row];
            }
            else {
                taskListElement = [self.finishedTaskListElements objectAtIndex:indexPath.row];
            }
            
            targetVC.taskListElement = taskListElement;
        }
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

// Needs to be here for unwind segue...
- (IBAction)unwindToTaskListElements:(UIStoryboardSegue *)unwindSegue {
    [self refreshTaskListElements];
}

#pragma mark UIActionSheet Delegate Methods

//lets us know the behaviour of the actionsheet
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: // Delete
            [self deleteTaskListDialog];
            break;
        case 1: // Rename
            [self renameTaskListDialog];
            break;
        case 2: // Toggle Finished
            [self toggleFinished];
            break;
        default:
            break;
    }
}

#pragma mark Helper Methods

- (void)deleteTaskListDialog {
    UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Are you sure you want to delete this task list?" message:@"" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    deleteAlert.tag = 0;
    [deleteAlert show];
}

- (void)renameTaskListDialog {
    UIAlertView *renameAlert = [[UIAlertView alloc] initWithTitle:@"Task List Name" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Change", nil];
    [renameAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [renameAlert textFieldAtIndex:0].text = self.taskList.listName;
    [renameAlert textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
    renameAlert.tag = 1;
    [renameAlert show];
}

- (void)toggleFinished {
    self.taskList.done = !self.taskList.done;
    [self.taskList saveEventually:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"TaskListChanged" object:nil];
        }
    }];
}

#pragma mark UIAlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 0) { // delete
        if (buttonIndex == 1) {
            // OK, time to delete
            
            [SVProgressHUD showWithStatus:@"Deleting Task List" maskType:SVProgressHUDMaskTypeBlack];
            [self.taskList deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [SVProgressHUD dismiss];
                if (!error) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"TaskListChanged" object:nil];
                    [self.navigationController popViewControllerAnimated:YES];
                }
                else {
                    UIAlertView *deleteFailAlert = [[UIAlertView alloc] initWithTitle:@"Could not delete task list" message:error.userInfo[@"error"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [deleteFailAlert show];
                }
            }];
        }
    }
    else if (alertView.tag == 1) { // rename
        if (buttonIndex == 1) {
            // Time to change the title
            
            // Get the title from the alertview
            NSString *newName = [alertView textFieldAtIndex:0].text;
            if ([newName isEqualToString:@""]) {
                UIAlertView *emptyNameAlert = [[UIAlertView alloc] initWithTitle:@"Could not rename task list" message:@"Name cannot be empty" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [emptyNameAlert show];
            }
            else {
                self.taskList.listName = newName;
                [self.taskList saveEventually:^(BOOL succeeded, NSError *error) {
                    if (!error) {
                        self.title = self.taskList.listName;
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"TaskListChanged" object:nil];
                    }
                }];
            }
            
        }
    }
}

@end
