//
//  NoHouseholdViewController.m
//  Roommates
//
//  Created by Gjermund Bjaanes on 26/02/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

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

// Model:
@property (strong, nonatomic) NSArray *invitations; // of Invitation *
@end

@implementation NoHouseholdViewController

#pragma mark getters and setters

// Just in case someone tries to use invitations before it is set
- (NSArray *)invitations {
    if (!_invitations) {
        _invitations = [[NSArray alloc] init];
    }
    return _invitations;
}

#pragma mark View Controller Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set ourselves as the tableview's delegate
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Set up a tableviewcontroller for the tableview (we need it for refresh controls)
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    self.tableViewController = tableViewController;
    [self addChildViewController:tableViewController];
    
    // Set up pull to refresh controls
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshInvitationsWithPull:) forControlEvents:UIControlEventValueChanged];
    tableViewController.refreshControl = refreshControl;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Turn off acceptbutton (until we have invitations)
    [self.acceptButton setTitle:@"" forState:UIControlStateNormal];
    [self.acceptButton setEnabled:NO];
    
    // Start refreshing (with animation)
    [self.tableView setContentOffset:CGPointMake(0, -self.tableViewController.refreshControl.frame.size.height) animated:YES];
    [self refreshInvitations];
}

#pragma mark Methods

- (void)refreshInvitations {
    // Start refresh animation
    [self.tableViewController.refreshControl beginRefreshing];
    
    // Get invitations
    PFQuery *invitationQuery = [Invitation query];
    [invitationQuery whereKey:@"invitee" equalTo:[User currentUser]];
    [invitationQuery includeKey:@"household"];
    [invitationQuery includeKey:@"inviter"];
    invitationQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [invitationQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.invitations = objects;
            
            // If we have more than 0 invitations, turn on accept button
            if (self.invitations.count > 0) {
                [self.acceptButton setTitle:@"Accept" forState:UIControlStateNormal];
                [self.acceptButton setEnabled:YES];
            }
            
            [self.tableView reloadData];
            [self.tableViewController.refreshControl endRefreshing];
        }
    }];
}

// For the pull down refresh thingy
- (void)refreshInvitationsWithPull:(UIRefreshControl *)sender {
    [self refreshInvitations];
}

- (IBAction)createNewHousehold {
    UIAlertView *createHouseholdAlert = [[UIAlertView alloc] initWithTitle:@"Create New Household"
                                                                   message:@""
                                                                  delegate:self
                                                         cancelButtonTitle:@"Cancel"
                                                         otherButtonTitles:@"Create", nil];
    [createHouseholdAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [createHouseholdAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // User pressed Create
        NSString *householdName = [alertView textFieldAtIndex:0].text;
        
        // Check if everything is OK to start creating the household
        if ([householdName isEqualToString:@""]) {
            UIAlertView *emptyHouseholdNameAlert = [[UIAlertView alloc] initWithTitle:@"Could not create new household"
                                                                              message:@"Empty Household Name"
                                                                             delegate:nil
                                                                    cancelButtonTitle:@"OK"
                                                                    otherButtonTitles:nil];
            [emptyHouseholdNameAlert show];
        }
        else if (![[User currentUser] isMemberOfAHousehold] || [User currentUser]) {
            [SVProgressHUD showWithStatus:@"Creating New Household" maskType:SVProgressHUDMaskTypeBlack];
            [PFCloud callFunctionInBackground:@"createNewHousehold"
                               withParameters:@{@"householdName": householdName}
                                        block:^(id object, NSError *error)
             {
                 [SVProgressHUD dismiss];
                 if (!error) {
                     // Refresh the user information after the cloud call (user is now member of a household)
                     [SVProgressHUD showWithStatus:@"Fetching user information" maskType:SVProgressHUDMaskTypeBlack];
                     [[PFUser currentUser] fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                         [SVProgressHUD dismiss];
                         if (!error) {
                             // Refreshed, set up Push
                             [User refreshChannels];
                             [self.navigationController popViewControllerAnimated:YES]; // unwind instead?
                         }
                         else {
                             UIAlertView *fetchUserAlert =
                                    [[UIAlertView alloc] initWithTitle:@"Household created."
                                                               message:@"Household created, but could not fetch user. Log out and back in again to solve this issue."
                                                              delegate:nil
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil];
                             [fetchUserAlert show];
                         }
                     }];
                 }
                 else {
                     UIAlertView *createHouseholdAlert =
                            [[UIAlertView alloc] initWithTitle:@"Create new Household failed."
                                                       message:error.userInfo[@"error"]
                                                      delegate:nil
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
                     [createHouseholdAlert show];
                 }
                 
             }];
            
        }
    }
}


- (IBAction)acceptInvitation {
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    
    if (selectedIndexPath) {
        Invitation *invitation = [self.invitations objectAtIndex:selectedIndexPath.row];
        [SVProgressHUD showWithStatus:@"Joining household" maskType:SVProgressHUDMaskTypeBlack];
        [PFCloud callFunctionInBackground:@"acceptInvitation"
                           withParameters:@{@"invitationId": invitation.objectId}
                                    block:^(id object, NSError *error)
         {
             [SVProgressHUD dismiss];
             if (!error) {
                 // Refresh the user information after the cloud call (user is now member of a household)
                 [SVProgressHUD showWithStatus:@"Fetching user information" maskType:SVProgressHUDMaskTypeBlack];
                 [[PFUser currentUser] fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                     [SVProgressHUD dismiss];
                     if (!error) {
                         // User refreshed, set up push
                         [User refreshChannels];
                         [self.navigationController popViewControllerAnimated:YES];
                     }
                     else {
                         UIAlertView *fetchUserAlert =
                         [[UIAlertView alloc] initWithTitle:@"Invitation accepted"
                                                    message:@"Invitation Accepted, but could not fetch user. Log out and back in again to solve this issue."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
                         [fetchUserAlert show];
                     }
                 }];
             }
             else {
                 UIAlertView *acceptInviteAlert = [[UIAlertView alloc] initWithTitle:@"Invitation not accepted"
                                                                             message:error.userInfo[@"error"]
                                                                            delegate:nil
                                                                   cancelButtonTitle:@"OK"
                                                                   otherButtonTitles:nil];
                 [acceptInviteAlert show];
             }
         }];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
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
    
    // Configure the cell...
    Invitation *invitation = [self.invitations objectAtIndex:indexPath.row];
    Household *household = invitation.household;
    User *inviter = invitation.inviter;
    
    cell.textLabel.text = [NSString stringWithFormat:@"Household: %@", household.householdName];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Invited by: %@", inviter.displayName];
    
    
    return cell;
}

// Header title
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Invitations";
}



@end
