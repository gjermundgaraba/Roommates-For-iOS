//
//  FeedViewController.m
//  Roommates
//
//  Created by Gjermund Bjaanes on 06/03/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import "FeedViewController.h"
#import <Parse/Parse.h>
#import "FetchEventClient.h"
#import "UserClient.h"
//#import "NoteClient.h"
#import "CreateNoteClient.h"
#import "SVProgressHUD.h"

@interface FeedViewController () <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate>
@property (strong, nonatomic) FetchEventClient *fetchEventClient;
@property (strong, nonatomic) CreateNoteClient *createNoteClient;
@property (nonatomic, strong) UserClient *userClient;
@property (strong, nonatomic) NSArray *events; //of PFObjects*
//@property (strong, nonatomic) NSArray *notes; // of PFObjects (used in iPad interface)
@property (weak, nonatomic) UIRefreshControl *refreshControl;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *noteContainerView;
@property (nonatomic, strong) UIButton *noteButton;
@property (nonatomic, strong) UIButton *allNotesButton;
@property (nonatomic, strong) UIView *fakeButtonBar;
@end

@implementation FeedViewController

/** Rewrites the getters for userClient
 and instansiates them if they don´t exist. **/

- (UserClient *)userClient {
    if (!_userClient) {
        _userClient = [[UserClient alloc] init];
    }
    return _userClient;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"Feed View Did Load");
    
    self.fetchEventClient = [[FetchEventClient alloc] init];
    self.createNoteClient = [[CreateNoteClient alloc] init];
    
    // Refresh newsfeed
    
    UIRefreshControl *refreshTable = [[UIRefreshControl alloc] init];
    [refreshTable addTarget:self action:@selector(refreshFeedWithPull:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshTable;
    [self.tableView addSubview:refreshTable];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Add new Notebutton
    
    UIButton *newNoteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [newNoteButton addTarget:self action:@selector(newNoteSegue) forControlEvents:UIControlEventTouchUpInside];
    [newNoteButton setTitle:@"New" forState:UIControlStateNormal];
    [self.view addSubview:newNoteButton];
    self.noteButton = newNoteButton;
    
    // Add see all notes button
    
    UIButton *seeAllNotesButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [seeAllNotesButton addTarget:self action:@selector(allNotesSegue) forControlEvents:UIControlEventTouchUpInside];
    [seeAllNotesButton setTitle:@"All" forState:UIControlStateNormal];
    [self.view addSubview:seeAllNotesButton];
    self.allNotesButton = seeAllNotesButton;
    
    // Ipad stuff :
    
    self.fakeButtonBar = [[UIView alloc] init];
    self.fakeButtonBar.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.fakeButtonBar];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //Start refreshanimation on table
    
    [self.tableView setContentOffset:CGPointMake(0, -self.refreshControl.frame.size.height) animated:YES];
    [self.refreshControl beginRefreshing];
    [self refreshEventsWithForceFetch:NO];
    
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    [self updateCustomUI];
}

- (void)updateCustomUI {
    
    //Making the custom UI on top of the screen
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        NSLog(@"Fixing up some fake bar");
        CGFloat footerX = 20;
        CGFloat footerY = self.noteContainerView.frame.size.height + 20 - 40;
        CGFloat footerWidth = self.noteContainerView.frame.size.width;
        
        CGFloat footerHeight = 40;
        self.fakeButtonBar.frame = CGRectMake(footerX, footerY, footerWidth, footerHeight);
        [self.view bringSubviewToFront:self.fakeButtonBar];
    }
    
    //int y = self.view.frame.size.height - 35;
    CGFloat y = self.noteContainerView.frame.size.height + 20 - 35;
    self.noteButton.frame = CGRectMake(28, y, 50, 30);
    [self.view bringSubviewToFront:self.noteButton];
    
    //int x = self.view.frame.size.width - 70;
    CGFloat x = self.noteContainerView.frame.size.width + 8 - 35;
    self.allNotesButton.frame = CGRectMake(x, y, 50, 30);
    [self.view bringSubviewToFront:self.allNotesButton];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Specifies the navigationControllers UI when feedview is diseappering
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.navigationController.navigationBar setBackgroundColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setTranslucent:NO];
    [super viewWillDisappear:animated];
}


// iPad rotation
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientatio
{
    [self updateCustomUI];
}

//Segues to all notes if user is logged in and member of a household
- (void)allNotesSegue {
    if ([self.userClient userIsLoggedInAndMemberOfAHousehold]) {
        [self performSegueWithIdentifier:@"allNotesSegue" sender:self];
    }
}

//Segues to newNoteAlertView if user is logged in and member of a household
- (void)newNoteSegue {
    if ([self.userClient userIsLoggedInAndMemberOfAHousehold]) {
        UIAlertView *newNoteAlert = [[UIAlertView alloc] initWithTitle:@"New Note" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        newNoteAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [newNoteAlert show];
    }
}

// Rewrites the setter for setEvents
- (void)setEvents:(NSArray *)events {
    _events = events;
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

//Refreshing the events with forcefetch
- (void)refreshEventsWithForceFetch:(BOOL)forceFetch {
    [self.fetchEventClient getLatestEventsInBackgroundWithForceFetch:forceFetch limit:20 block:^(NSArray *events, NSError *error) {
        self.events = events;
    }];
}

//Refreshing the events with pulldown
- (void)refreshFeedWithPull:(UIRefreshControl *)sender {
    [self refreshEventsWithForceFetch:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (self.events) {
        return self.events.count;
    }
    else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Gets the events to show in the tableView
    static NSString *CellIdentifier = @"EventCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    PFObject *event = [self.events objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"Event: %@", event[@"description"]];
    
    return cell;
}

 //Returns the height for each row at the tableview
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54;
}

#pragma mark UIAlert View Delegate Methods

// Lets us know when UIAlertView events happen
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [SVProgressHUD showWithStatus:@"Creating new Note"];
        
        NSString *body = [alertView textFieldAtIndex:0].text;
        [self.createNoteClient createNewNoteInBackgroundWithBody:body block:^(NSError *error) {
            [SVProgressHUD dismiss];
            if (!error) {
                //[SVProgressHUD showSuccessWithStatus:@"New note created!"];
                // Shoulde force some sort of force fetch for notes. This might be a NSNotification Center kinda buisness
                
            }
            else {
                UIAlertView *newNoteAlert = [[UIAlertView alloc] initWithTitle:@"Error." message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [newNoteAlert show];
            }
        }];
    }
}


@end
