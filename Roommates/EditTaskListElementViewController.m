
#import "EditTaskListElementViewController.h"
#import "SVProgressHUD.h"

@interface EditTaskListElementViewController ()
@property (weak, nonatomic) IBOutlet UITextField *elementNameTextField;
@property (weak, nonatomic) IBOutlet UISwitch *elementFinishedSlider;
@property (weak, nonatomic) IBOutlet UILabel *finishedByLabel;
@property (weak, nonatomic) IBOutlet UILabel *createdByLabel;

@end

@implementation EditTaskListElementViewController

#pragma mark View Controller Life Cycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.taskListElement) {
        self.title = self.taskListElement.elementName;
        
        BOOL isFinished = self.taskListElement.finishedBy ? YES : NO;
        
        self.elementNameTextField.text = self.taskListElement.elementName;
        self.elementFinishedSlider.on = isFinished;
        self.finishedByLabel.text = isFinished ? self.taskListElement.finishedBy.displayName : @"";
        self.createdByLabel.text = self.taskListElement.createdBy.displayName;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveResetHouseholdScenesNotification:) name:@"ResetHouseholdScenes" object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![[User currentUser] isMemberOfAHousehold]) {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
}

#pragma mark methods

- (void)didReceiveResetHouseholdScenesNotification:(NSNotificationCenter *)notificationCenter {
    [self.navigationController popToRootViewControllerAnimated:NO];
}


- (IBAction)saveButtonPressed:(id)sender {
    self.taskListElement.elementName = self.elementNameTextField.text;
    if (self.elementFinishedSlider.on && !self.taskListElement.finishedBy) {
        self.taskListElement.finishedBy = (User *)[PFUser currentUser];
    }
    else if (!self.elementFinishedSlider.on && self.taskListElement.finishedBy) {
        [self.taskListElement removeObjectForKey:@"finishedBy"];
    }
    
    [SVProgressHUD showWithStatus:@"Saving Task List Element" maskType:SVProgressHUDMaskTypeBlack];
    [self.taskListElement saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [SVProgressHUD dismiss];
        if (!error) {
            [SVProgressHUD showSuccessWithStatus:@"Task List Element Saved!"];
            [self performSegueWithIdentifier:@"unwindToTaskListElementsSegue" sender:nil];
        } else {
            [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
        }
        
    }];
}


- (IBAction)deleteButtonPressed {
    UIAlertView *deleteListAlert = [[UIAlertView alloc] initWithTitle:@"Delete List Element" message:@"Are you sure you want to delete this element?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [deleteListAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self.taskListElement deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                [SVProgressHUD showSuccessWithStatus:@"Task List Element Deleted!"];
                [self performSegueWithIdentifier:@"unwindToTaskListElementsSegue" sender:nil];
            } else {
                [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
            }
        }];
    }
}




@end
