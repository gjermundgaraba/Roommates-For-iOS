
#import "NoteTableViewController.h"
#import "NoteTableViewCell.h"
#import "Note.h"
#import "Household.h"
#import "SVProgressHUD.h"
#import "NSDate+NVTimeAgo.h"

@interface NoteTableViewController ()
@property (strong, nonatomic) NSArray *notes;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property int maxNumberOfNotes;
@end

static NSString *noteCellIdentifier = @"NoteCellIdentifier";
static NSString *loadMoreNotesIdentifier = @"LoadMoreNotesIdentifier";

@implementation NoteTableViewController

#pragma mark life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateUserInteractionEnabled];
    
    self.maxNumberOfNotes = 5;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self updateNotes];
    
    self.tableView.estimatedRowHeight = 80.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.refreshControl = [[UIRefreshControl alloc]init];
    [self.tableView addSubview:self.refreshControl];
    [self.refreshControl addTarget:self action:@selector(updateNotes) forControlEvents:UIControlEventValueChanged];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNotes) name:@"NewNoteCreated" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveResetHouseholdScenesNotification:) name:@"ResetHouseholdScenes" object:nil];
}

#pragma mark methods

- (void)didReceiveResetHouseholdScenesNotification:(NSNotificationCenter *)notificationCenter {
    [self updateUserInteractionEnabled];
    [self updateNotes];
}

- (void)updateUserInteractionEnabled {
    if ([[User currentUser] isMemberOfAHousehold]) {
        self.tableView.userInteractionEnabled = YES;
    } else {
        self.tableView.userInteractionEnabled = NO;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)updateNotes {
    User *user = [User currentUser];
    if ([user isMemberOfAHousehold]) {
        PFQuery *queryForNotes = [Note query];
        [queryForNotes whereKey:@"household" equalTo:user.activeHousehold];
        [queryForNotes includeKey:@"createdBy"];
        [queryForNotes orderByDescending:@"updatedAt"];
        queryForNotes.limit = self.maxNumberOfNotes;
        
        if (self.notes.count == 0 && [queryForNotes hasCachedResult]) {
            queryForNotes.cachePolicy = kPFCachePolicyCacheThenNetwork;
        } else {
            queryForNotes.cachePolicy = kPFCachePolicyNetworkOnly;
        }
        
        [queryForNotes findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            [self.refreshControl endRefreshing];
            if (!error) {
                self.notes = objects;
                [self.tableView reloadData];
            } else {
                [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
            }
        }];
    } else {
        self.notes = [NSArray array];
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.notes.count > 0) {
        return self.notes.count + 1;
    } else {
        return 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    if (indexPath.row < self.notes.count) {
        cell = [tableView dequeueReusableCellWithIdentifier:noteCellIdentifier forIndexPath:indexPath];
        [self configureCell:(NoteTableViewCell *)cell forRowAtIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:loadMoreNotesIdentifier];
    }
    
    return cell;
}

- (void)configureCell:(NoteTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[NoteTableViewCell class]]) {
        Note *note = [self.notes objectAtIndex:indexPath.row];
        
        cell.displayName.text = note.createdBy.displayName;
        
        cell.noteBody.text = note.body;
        
        NSDate *date = note.createdAt;
        cell.time.text = [date formattedAsTimeAgo];
        
        cell.profilePicture.image = [UIImage imageNamed:@"placeholder"];
        cell.profilePicture.file = note.createdBy.profilePicture;
        [cell.profilePicture loadInBackground];
        
        cell.userInteractionEnabled = NO;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.notes.count) {
        self.maxNumberOfNotes += 5;
        [self updateNotes];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Notes";
}

@end
