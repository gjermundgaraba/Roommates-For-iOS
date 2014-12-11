
#import "EventTableViewController.h"
#import "EventTableViewCell.h"
#import <Parse/Parse.h>
#import "User.h"
#import "Event.h"
#import "Household.h"
#import "SVProgressHUD.h"

@interface EventTableViewController ()
@property (nonatomic, strong) NSArray *events;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@end

@implementation EventTableViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateUserInteractionEnabled];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self updateEvents];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.refreshControl = [[UIRefreshControl alloc]init];
    [self.tableView addSubview:self.refreshControl];
    [self.refreshControl addTarget:self action:@selector(updateEvents) forControlEvents:UIControlEventValueChanged];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveResetHouseholdScenesNotification:) name:@"ResetHouseholdScenes" object:nil];

}

#pragma mark - Methods

- (void)didReceiveResetHouseholdScenesNotification:(NSNotificationCenter *)notificationCenter {
    [self updateUserInteractionEnabled];
    [self updateEvents];
}

- (void)updateUserInteractionEnabled {
    if ([[User currentUser] isMemberOfAHousehold]) {
        self.tableView.userInteractionEnabled = YES;
    } else {
        self.tableView.userInteractionEnabled = NO;
    }
}

- (void)updateEvents {
    User *user = [User currentUser];
    if ([user isMemberOfAHousehold]) {
        PFQuery *query = [Event query];
        [query whereKey:@"household" equalTo:user.activeHousehold];
        [query includeKey:@"user"];
        [query includeKey:@"household"];
        [query includeKey:@"objects"];
        [query orderByDescending:@"createdAt"];
        
        if (self.events.count == 0 && [query hasCachedResult]) {
            query.cachePolicy = kPFCachePolicyCacheThenNetwork;
        } else {
            query.cachePolicy = kPFCachePolicyNetworkOnly;
        }
        
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            [self.refreshControl endRefreshing];
            if (!error) {
                self.events = objects;
                [self.tableView reloadData];
            } else {
                [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
            }
        }];
    } else {
        self.events = [NSArray array];
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.events.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(@"Events", nil);
}


- (void)configureCell:(EventTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    Event *event = [self.events objectAtIndex:indexPath.row];
    
    cell.eventTitle.text = event.descriptionTitle;
    
    cell.eventText.text = event.descriptionString;
    
    cell.profilePicture.image = [UIImage imageNamed:@"placeholder"];
    cell.profilePicture.file = event.user.profilePicture;
    [cell.profilePicture loadInBackground];
    
    /*NSDate *date = event.createdAt;
    cell.detailTextLabel.text = [date formattedAsTimeAgo];*/
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EventTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EventCellIdentifier" forIndexPath:indexPath];
    [self configureCell:cell forRowAtIndexPath:indexPath];
    return cell;
}

@end
