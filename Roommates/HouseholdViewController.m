//
//  HouseholdViewControllerTMP.m
//  Roommates
//
//  Created by Gjermund Bjaanes on 07/03/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import "HouseholdViewController.h"
#import "SVProgressHUD.h"
#import <Parse/Parse.h>
#import "Household.h"
#import "User.h"

@interface HouseholdViewController ()
@property (weak, nonatomic) IBOutlet UILabel *householdNameLabel;
@end


@implementation HouseholdViewController

#pragma mark View Controller Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // Set up the UI:
    self.householdNameLabel.text = @"N/A"; // Before fetch, its N/A
    
    
    Household *household = [User currentUser].activeHousehold;
    [household fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            // If we got the household, change the name label, else we just keep using N/A
            self.householdNameLabel.text = household[@"householdName"];
        }
    }];
}


@end
