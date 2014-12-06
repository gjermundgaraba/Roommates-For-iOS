
#import "ProfileTableViewController.h"
#import <Parse/Parse.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import "LoginViewController.h"
#import "User.h"

// Defines the sections and rows, so we can more readable
// find the sections and rows later
#define INFORMATION_SECTION 0
#define EMAIL_ROW 0
#define DISPLAY_NAME_ROW 1

#define SETTINGS_SECTION 1
#define HOUSEHOLD_SETTINGS_ROW 0
#define PROFILE_SETTINGS_ROW 1
#define CHANGE_PASSWORD_ROW 2
#define LOGOUT_ROW 3


@interface ProfileTableViewController () <UIAlertViewDelegate>
@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *informationCells;
@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *settingsCells;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic)  User *currentUser;
@end

@implementation ProfileTableViewController

#pragma mark setters and getters

- (User *)currentUser {
    return [User currentUser];
}

#pragma mark View Controller Life Cycle

- (void) viewWillAppear:(BOOL)animated {
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [self.tableView reloadData];
    [super viewDidAppear:animated];
}

#pragma mark - Table view data source

- (void)setCellUnClickable:(UITableViewCell *)cell
{
    cell.userInteractionEnabled = NO;
    cell.textLabel.textColor = [UIColor grayColor];
    cell.accessoryType = UITableViewCellAccessoryNone;
}

- (void)setCellClickable:(UITableViewCell *)cell
{
    cell.userInteractionEnabled = YES;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    BOOL userIsLinkedWithFacebook = [PFFacebookUtils isLinkedWithUser:self.currentUser];
    
    if (indexPath.section == INFORMATION_SECTION) {
        cell = [self.informationCells objectAtIndex:indexPath.row];
        switch (indexPath.row) {
            case EMAIL_ROW:
                cell.detailTextLabel.text = self.currentUser.email;
                cell.userInteractionEnabled = NO;
                break;
            case DISPLAY_NAME_ROW:
                cell.detailTextLabel.text = self.currentUser.displayName;
                cell.userInteractionEnabled = NO;
                break;
            default:
                break;
        }
    }
    else if (indexPath.section == 1) {
        cell = [self.settingsCells objectAtIndex:indexPath.row];
        switch (indexPath.row) {
            case HOUSEHOLD_SETTINGS_ROW:
                break;
            case PROFILE_SETTINGS_ROW: {
                if (userIsLinkedWithFacebook) {
                    [self setCellUnClickable:cell];
                }
                else {
                    
                }
                break;
            }
            case CHANGE_PASSWORD_ROW: {
                if (userIsLinkedWithFacebook) {
                    [self setCellUnClickable:cell];
                }
                else {
                    [self setCellClickable:cell];
                }
                break;
            }
            case LOGOUT_ROW:
                break;
            default:
                break;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SETTINGS_SECTION) {
        if (indexPath.row == HOUSEHOLD_SETTINGS_ROW) {
            if ([[User currentUser] isMemberOfAHousehold]) {
                [self performSegueWithIdentifier:@"HasHouseholdSegue" sender:nil];
            }
            else {
                [self performSegueWithIdentifier:@"NoHouseholdSegue" sender:nil];
            }
        }
        else if (indexPath.row == LOGOUT_ROW) {
            UIAlertView *logOutAlert = [[UIAlertView alloc] initWithTitle:@"Warning"
                          message:@"Are you sure you want to log out?"
                         delegate:self
                cancelButtonTitle:@"Cancel"
                otherButtonTitles:@"OK", nil];
            [logOutAlert show];
        }
    }
}


#pragma mark Alert View Delegate Methods

- (void)showLoginView {
    LoginViewController *notLoggedInVC =
    [self.storyboard instantiateViewControllerWithIdentifier:@"NotLoggedInView"];
    [self presentViewController:notLoggedInVC animated:YES completion:nil];
    [self.tabBarController setSelectedIndex:0];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    if (buttonIndex == 1) {
        if ([PFUser currentUser]) {
            [PFQuery clearAllCachedResults];
            [PFUser logOut];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ResetHouseholdScenes" object:nil];
            
            [User refreshChannels];
        }
        
        [self showLoginView];
    }
}


@end
