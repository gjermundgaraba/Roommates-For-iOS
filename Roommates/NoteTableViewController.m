//
//  NoteTableViewController.m
//  Roommates
//
//  Created by Gjermund Bjaanes on 09/12/14.
//  Copyright (c) 2014 Gjermund Bjaanes. All rights reserved.
//

#import "NoteTableViewController.h"
#import "NoteUITableViewCell.h"
#import "Note.h"
#import "Household.h"
#import "SVProgressHUD.h"

@interface NoteTableViewController ()
@property (strong, nonatomic) NSArray *notes;
@property (strong, nonatomic) NoteUITableViewCell *prototypeCell;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@end

static NSString *noteCellIdentifier = @"NoteCellIdentifier";

@implementation NoteTableViewController

- (NoteUITableViewCell *)prototypeCell {
    if (!_prototypeCell) {
        _prototypeCell = [self.tableView dequeueReusableCellWithIdentifier:noteCellIdentifier];
    }
    return _prototypeCell;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateUserInteractionEnabled];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self updateNotes];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.refreshControl = [[UIRefreshControl alloc]init];
    [self.tableView addSubview:self.refreshControl];
    [self.refreshControl addTarget:self action:@selector(updateNotes) forControlEvents:UIControlEventValueChanged];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNotes) name:@"NewNoteCreated" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveResetHouseholdScenesNotification:) name:@"ResetHouseholdScenes" object:nil];
}

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
    if ([[User currentUser] isMemberOfAHousehold]) {
        PFQuery *queryForNotes = [Note query];
        Household *household = [User currentUser].activeHousehold;
        [queryForNotes whereKey:@"household" equalTo:household];
        [queryForNotes includeKey:@"createdBy"];
        [queryForNotes orderByDescending:@"updatedAt"];
        
        if (self.notes.count == 0) {
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
    return self.notes.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NoteUITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:noteCellIdentifier forIndexPath:indexPath];
    
    [self configureCell:cell forRowAtIndexPath:indexPath];
    // Configure the cell...
    
    return cell;
}

- (void)configureCell:(NoteUITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[NoteUITableViewCell class]])
    {
        Note *note = [self.notes objectAtIndex:indexPath.row];
        
        cell.displayName.text = note.createdBy.displayName;
        
        cell.noteBody.text = note.body;
        
        cell.profilePicture.image = [UIImage imageNamed:@"placeholder"];
        cell.profilePicture.file = note.createdBy.profilePicture;
        [cell.profilePicture loadInBackground];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Notes";
}

@end
