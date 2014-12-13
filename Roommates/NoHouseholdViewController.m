
#import "NoHouseholdViewController.h"
#import <Parse/Parse.h>
#import "SVProgressHUD.h"
#import "Invitation.h"
#import "User.h"
#import "Household.h"

@interface NoHouseholdViewController () <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;
@property (strong, nonatomic) UITableViewController *tableViewController;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray *invitations; // of Invitation *
@end

@implementation NoHouseholdViewController

#pragma mark getters and setters

- (NSArray *)invitations {
    if (!_invitations) {
        _invitations = [[NSArray alloc] init];
    }
    return _invitations;
}

#pragma mark View Controller Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    self.tableViewController = tableViewController;
    [self addChildViewController:tableViewController];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshInvitationsWithPull:) forControlEvents:UIControlEventValueChanged];
    tableViewController.refreshControl = refreshControl;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.acceptButton setTitle:@"" forState:UIControlStateNormal];
    [self.acceptButton setEnabled:NO];
    
    [self.tableView setContentOffset:CGPointMake(0, -self.tableViewController.refreshControl.frame.size.height) animated:YES];
    [self refreshInvitations];
}

#pragma mark Methods

- (void)refreshInvitations {
    [self.tableViewController.refreshControl beginRefreshing];
    
    PFQuery *invitationQuery = [Invitation query];
    [invitationQuery whereKey:@"invitee" equalTo:[User currentUser]];
    [invitationQuery includeKey:@"household"];
    [invitationQuery includeKey:@"inviter"];
    
    if ([invitationQuery hasCachedResult]) {
        invitationQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    } else {
        invitationQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    }
    
    
    [invitationQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.invitations = objects;
            
            if (self.invitations.count > 0) {
                [self.acceptButton setTitle:NSLocalizedString(@"Accept", nil) forState:UIControlStateNormal];
                [self.acceptButton setEnabled:YES];
            }
            
            [self.tableView reloadData];
            [self.tableViewController.refreshControl endRefreshing];
        }
    }];
}

- (void)refreshInvitationsWithPull:(UIRefreshControl *)sender {
    [self refreshInvitations];
}

- (IBAction)createNewHousehold {
    UIAlertView *createHouseholdAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Create New Household", nil)
                                                                   message:@""
                                                                  delegate:self
                                                         cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                         otherButtonTitles:NSLocalizedString(@"Create", nil), nil];
    [createHouseholdAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [createHouseholdAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // User pressed Create
        NSString *householdName = [alertView textFieldAtIndex:0].text;
        
        if ([householdName isEqualToString:@""]) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Empty Household Name", nil)];
        }
        else if (![[User currentUser] isMemberOfAHousehold] || [User currentUser]) {
            [SVProgressHUD showWithStatus:NSLocalizedString(@"Creating New Household", nil) maskType:SVProgressHUDMaskTypeBlack];
            [PFCloud callFunctionInBackground:@"createNewHousehold"
                               withParameters:@{@"householdName": householdName}
                                        block:^(id object, NSError *error)
             {
                 [SVProgressHUD dismiss];
                 if (!error) {
                     [SVProgressHUD showWithStatus:NSLocalizedString(@"Fetching user information", nil) maskType:SVProgressHUDMaskTypeBlack];
                     [[PFUser currentUser] fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                         [SVProgressHUD dismiss];
                         if (!error) {
                             [User refreshChannels];
                             [[NSNotificationCenter defaultCenter] postNotificationName:@"ResetHouseholdScenes" object:nil];
                             [self.navigationController popViewControllerAnimated:YES];
                         }
                         else {
                             [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Household created, but could not fetch user info. Log out and back in again to solve this issue.", nil)];
                         }
                     }];
                 }
                 else {
                     [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
                 }
                 
             }];
            
        }
    }
}


- (IBAction)acceptInvitation {
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    
    if (selectedIndexPath) {
        Invitation *invitation = [self.invitations objectAtIndex:selectedIndexPath.row];
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Joining household", nil) maskType:SVProgressHUDMaskTypeBlack];
        [PFCloud callFunctionInBackground:@"acceptInvitation"
                           withParameters:@{@"invitationId": invitation.objectId}
                                    block:^(id object, NSError *error)
         {
             [SVProgressHUD dismiss];
             if (!error) {
                 
                 // Refresh the user information after the cloud call (user is now member of a household)
                 [SVProgressHUD showWithStatus:NSLocalizedString(@"Fetching user information", nil) maskType:SVProgressHUDMaskTypeBlack];
                 [[PFUser currentUser] fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                     [SVProgressHUD dismiss];
                     if (!error) {
                         [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Invitation accepted!", nil)];
                         [User refreshChannels];
                         [[NSNotificationCenter defaultCenter] postNotificationName:@"ResetHouseholdScenes" object:nil];
                         [self.navigationController popViewControllerAnimated:YES];
                     }
                     else {
                         [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Invitation accepted, but could not fetch user. Log out and back in again to solve this issue.", nil)];
                     }
                 }];
             }
             else {
                 [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
             }
         }];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.invitations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"invitationCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Invitation *invitation = [self.invitations objectAtIndex:indexPath.row];
    Household *household = invitation.household;
    User *inviter = invitation.inviter;
    
    cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Household: %@", nil), household.householdName];
    cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Invited by: %@", nil), inviter.displayName];
    
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(@"Invitations", nil);
}



@end
