
#import "HouseholdTableViewController.h"
#import <Parse/Parse.h>
#import "SVProgressHUD.h"
#import "User.h"
#import "Household.h"

// defines section and row numbers (for refrence later)
#define HOUSEHOLD_INFORMATION_SECTION 0
#define HOUSEHOLD_NAME_ROW 0

#define HOUSEHOLD_SETTINGS_SECTION 1
#define HOUSEHOLD_MEMBERS_ROW 0
#define HOUSEHOLD_INVITE_ROOMMATE_ROW 1
#define HOUSEHOLD_LEAVE_HOUSEHOLD_ROW 2

// defines alert view tag numbers
#define LEAVE_HOUSEHOLD_TAG 0
#define INVITE_TO_HOUSEHOLD_TAG 1

@interface HouseholdTableViewController () <UIAlertViewDelegate>
@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *householdInformationCells;
@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *householdSettingsCells;
@property (strong, nonatomic) Household *household;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation HouseholdTableViewController

#pragma mark getters and setters

- (void)setHousehold:(Household *)household {
    _household = household;
    [self.tableView reloadData];
}

#pragma mark View Controller Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[User currentUser].activeHousehold fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            self.household = (Household *)object;
        }
    }];
}

- (void) viewWillAppear:(BOOL)animated {
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
    [super viewWillAppear:animated];
}

#pragma mark Table View Controller Delegate Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    if (indexPath.section == HOUSEHOLD_INFORMATION_SECTION) {
        cell = [self.householdInformationCells objectAtIndex:indexPath.row];
        if (indexPath.row == HOUSEHOLD_NAME_ROW) {
            [cell setUserInteractionEnabled:NO];
            if (self.household) {
                cell.detailTextLabel.text = self.household.householdName;
            } else {
                cell.detailTextLabel.text = NSLocalizedString(@"N/A", nil);
            }
        }
    } else if (indexPath.section == HOUSEHOLD_SETTINGS_SECTION) {
        cell = [self.householdSettingsCells objectAtIndex:indexPath.row];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == HOUSEHOLD_SETTINGS_SECTION) {
        if (indexPath.row == HOUSEHOLD_INVITE_ROOMMATE_ROW) {
            UIAlertView *inviteAlert =
                    [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invite Rommates to Household (Email)", nil)
                                               message:@""
                                              delegate:self
                                     cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                     otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
            inviteAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
            [inviteAlert textFieldAtIndex:0].keyboardType = UIKeyboardTypeEmailAddress;
            inviteAlert.tag = INVITE_TO_HOUSEHOLD_TAG; // To be able to identify it in clickedButtonAtIndex
            [inviteAlert show];
        } else if (indexPath.row == HOUSEHOLD_LEAVE_HOUSEHOLD_ROW) {
            UIAlertView *leaveAlert =
                    [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil)
                                               message:NSLocalizedString(@"Are you sure you want to leave this household", nil)
                                              delegate:self
                                     cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                     otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
            leaveAlert.tag = LEAVE_HOUSEHOLD_TAG; // To be able to identify it in clickedButtonAtIndex
            [leaveAlert show];
        }
    }
}

#pragma mark Methods

- (void)leaveHousehold {
    if ([[User currentUser] isMemberOfAHousehold]) {
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Leaving household", nil) maskType:SVProgressHUDMaskTypeBlack];
        
        Household *household = [User currentUser].activeHousehold;
        [PFCloud callFunctionInBackground:@"leaveHousehold"
                           withParameters:@{@"householdId": household.objectId}
                                    block:^(id object, NSError *error)
         {
             [SVProgressHUD dismiss];
             if (!error) {
                 // Just sending block back, is that really the right thing to do?
                 [SVProgressHUD showWithStatus:NSLocalizedString(@"Fetching user information", nil) maskType:SVProgressHUDMaskTypeBlack];
                 [[PFUser currentUser] fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                     [SVProgressHUD dismiss];
                     if (!error) {
                         [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Left Household", nil)];
                         [User refreshChannels];
                         [[NSNotificationCenter defaultCenter] postNotificationName:@"ResetHouseholdScenes" object:nil];
                         [self.navigationController popViewControllerAnimated:YES];
                     } else {
                         [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Could not refresh user info. Please log out and back in again.", nil)];
                     }
                     
                 }];
             } else {
                 [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
             }
         }];
    } else {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"You cannot leave a household without beeing in one.", nil)];
    }
}

- (void)inviteRoommateToHouseholdWithUsername:(NSString *)invitee {
    if ([invitee isEqualToString:@""]) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Empty email. Please fill out an email", nil)];
    } else if ([[User currentUser] isMemberOfAHousehold]) {
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Inviting user to Household", nil) maskType:SVProgressHUDMaskTypeBlack];
        
        PFObject *household = [User currentUser].activeHousehold;
        [PFCloud callFunctionInBackground:@"inviteUserToHousehold"
                           withParameters:@{@"username": invitee, @"householdId" : household.objectId}
                                    block:^(id object, NSError *error)
         {
             [SVProgressHUD dismiss];
             if (!error) {
                 [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"User was invited to household!", nil)];
             } else {
                 [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
             }
         }];
        
    }

}

#pragma mark UIAlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    if (alertView.tag == LEAVE_HOUSEHOLD_TAG) {
        if (buttonIndex == 1) {
            [self leaveHousehold];
        }
    } else if (alertView.tag == INVITE_TO_HOUSEHOLD_TAG) {
        if (buttonIndex == 1) {
            NSString *invitee = [alertView textFieldAtIndex:0].text;
            [self inviteRoommateToHouseholdWithUsername:invitee];
        }
    }
}


@end
