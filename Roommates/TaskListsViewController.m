//
//  TaskListsViewController.m
//  Roommates
//
//  Created by Gjermund Bjaanes on 05/01/15.
//  Copyright (c) 2015 Gjermund Bjaanes. All rights reserved.
//

#import "TaskListsViewController.h"
#import "User.h"
#import "TaskList.h"
#import "SVProgressHUD.h"


@implementation TaskListsViewController

- (IBAction)addTaskListButtonPressed:(id)sender {
    if ([[User currentUser] isMemberOfAHousehold]) {
        UIAlertView *addTaskListAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add New Task List", nil)
                                                                   message:@""
                                                                  delegate:self
                                                         cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                         otherButtonTitles:NSLocalizedString(@"Add", nil), nil];
        addTaskListAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [addTaskListAlert textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
        [addTaskListAlert show];
    } else {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Not member of a household! Go to Me->Household Settings.", nil)];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // Add clicked
        NSString *listName = [alertView textFieldAtIndex:0].text;
        
        if ([listName isEqualToString:@""]) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"List Name is Empty", nil)];
        } else if ([User currentUser] && [User currentUser].isMemberOfAHousehold) {
            PFACL *acl = [PFACL ACL];
            [acl setReadAccess:YES forRoleWithName:[User currentUser].householdChannel];
            [acl setWriteAccess:YES forRoleWithName:[User currentUser].householdChannel];
            
            TaskList *newTaskList = (TaskList *)[PFObject objectWithClassName:@"TaskList"];
            newTaskList.listName  = listName;
            newTaskList.done = NO;
            newTaskList.createdBy = [User currentUser];
            newTaskList.household = [User currentUser].activeHousehold;
            newTaskList.ACL = acl;
            
            [SVProgressHUD showWithStatus:NSLocalizedString(@"Creating new Task List", nil) maskType:SVProgressHUDMaskTypeBlack];
            [newTaskList saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [SVProgressHUD dismiss];
                if (!error) {
                    [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"New Task List Created!", nil)];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"TaskListChanged" object:nil];
                }
                else {
                    [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
                }
            }];
        }
    }
}

@end
