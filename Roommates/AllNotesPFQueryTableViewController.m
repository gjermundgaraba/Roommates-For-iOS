
#import "AllNotesPFQueryTableViewController.h"
#import "NSDate+NVTimeAgo.h"
#import "Note.h"

@interface AllNotesPFQueryTableViewController ()

@end

@implementation AllNotesPFQueryTableViewController

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // Customize the table
        
        self.parseClassName = @"Note";
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = @"createdBy";
        
        // Uncomment the following line to specify the key of a PFFile on the PFObject to display in the imageView of the default cell style
        // self.imageKey = @"image";
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // The number of objects to show per page
        self.objectsPerPage = 5;
    }
    return self;
}



#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNewNoteCreated:) name:@"NewNoteCreated" object:nil];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveResetHouseholdScenesNotification:) name:@"ResetHouseholdScenes" object:nil];
}

- (void)didReceiveResetHouseholdScenesNotification:(NSNotificationCenter *)notificationCenter {
    [self loadObjects];
}

- (void)didReceiveNewNoteCreated:(NSNotificationCenter *)notificationCenter {
    [self loadObjects];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

/*
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */


#pragma mark - PFQueryTableViewController

- (void)objectsWillLoad {
    [super objectsWillLoad];
    
    // This method is called before a PFQuery is fired to get more objects
}

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
    // This method is called every time objects are loaded from Parse via the PFQuery
}


// Override to customize what kind of query to perform on the class. The default is to query for
// all objects ordered by createdAt descending.
- (PFQuery *)queryForTable {
    PFQuery *query = [Note query];
    if ([[User currentUser] isMemberOfAHousehold]) {
        [query whereKey:@"household" equalTo:[User currentUser].activeHousehold];
        [query includeKey:@"createdBy"];
    }
    else { // Should not happen, user should never be here
        // Not member of a household, stop everyting
        query = nil;
        [self clear];
        [self objectsDidLoad:[[NSError alloc] init]];
        [self.refreshControl endRefreshing]; // Manually stopping the refresh animation
        return  query;
    }
    
    // If Pull To Refresh is enabled, query against the network by default.
    if (self.pullToRefreshEnabled) {
        query.cachePolicy = kPFCachePolicyNetworkOnly;
    }
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if (self.objects.count == 0 && [query hasCachedResult]) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [query orderByDescending:@"createdAt"];
    
    return query;
}



// Override to customize the look of a cell representing an object. The default is to display
// a UITableViewCellStyleDefault style cell with the label being the textKey in the object,
// and the imageView being the imageKey in the object.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
                        object:(PFObject *)object
{
    Note *note = (Note *)object;
    static NSString *CellIdentifier = @"Cell";
    
    PFTableViewCell *cell = (PFTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell
    NSString *displayName = note.createdBy.displayName;
    NSString *timeAgo = [note.createdAt formattedAsTimeAgo];
    
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.text = note.body;
    
    cell.detailTextLabel.numberOfLines = 1;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", displayName, timeAgo];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 84;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Notes";
}

#pragma mark - UITableViewDelegate

// User selected a row
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    
    // Check that we are NOT on the "Load More" row.
    if (indexPath.row < self.objects.count) {
        // Find the note and set up an alert to show more info to the user (with the alert)
        Note *note = [self.objects objectAtIndex:indexPath.row];
        NSString *timeAgo = [note.createdAt formattedAsTimeAgo];
        
        NSString *title = [NSString stringWithFormat:@"%@ %@", note.createdBy.displayName, timeAgo];
        UIAlertView *noteAlertView = [[UIAlertView alloc] initWithTitle:title message:note.body delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
        [noteAlertView show];
    }
    
    
}

@end
