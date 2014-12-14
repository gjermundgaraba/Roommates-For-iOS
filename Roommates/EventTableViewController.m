
#import "EventTableViewController.h"
#import "EventTableViewCell.h"
#import <Parse/Parse.h>
#import "User.h"
#import "Event.h"
#import "Household.h"
#import "SVProgressHUD.h"
#import "NSDate+NVTimeAgo.h"

@interface EventTableViewController ()
@property (nonatomic, strong) NSArray *events;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property int maxNumberOfEvents;
@property BOOL loadMoreShouldBeShown;
@end

static NSString *eventCellIdentifier = @"EventCellIdentifier";
static NSString *loadMoreEventsIdentifier = @"LoadMoreEvents";

@implementation EventTableViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.maxNumberOfEvents = 5;
    self.loadMoreShouldBeShown = YES;
    
    [self updateUserInteractionEnabled];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self updateEvents];
    
    self.tableView.estimatedRowHeight = 80.0;
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
        query.limit = self.maxNumberOfEvents;
        
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
                
                [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                    if (!error) {
                        if (self.events.count >= number) {
                            self.loadMoreShouldBeShown = NO;
                            [self.tableView reloadData];
                        } else {
                            self.loadMoreShouldBeShown = YES;
                            [self.tableView reloadData];
                        }
                    }
                }];
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
    int numberOfRows = 0;
    
    if (self.events.count > 0) {
        numberOfRows += self.events.count;
    }
    
    if (numberOfRows > 0 && self.loadMoreShouldBeShown) {
        numberOfRows += 1;
    }
    
    return numberOfRows;
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
    cell.profilePicture.clipsToBounds = YES;
    cell.profilePicture.layer.cornerRadius = cell.profilePicture.frame.size.height / 2;
    cell.profilePicture.layer.masksToBounds = YES;
    [cell.profilePicture loadInBackground];
    
    NSDate *date = event.createdAt;
    cell.time.text = [date formattedAsTimeAgo];
    
    cell.userInteractionEnabled = NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    if (indexPath.row < self.events.count) {
        cell = [tableView dequeueReusableCellWithIdentifier:eventCellIdentifier forIndexPath:indexPath];
        [self configureCell:(EventTableViewCell *)cell forRowAtIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:loadMoreEventsIdentifier forIndexPath:indexPath];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.events.count) {
        self.maxNumberOfEvents += 5;
        [self updateEvents];
    }
}

@end
