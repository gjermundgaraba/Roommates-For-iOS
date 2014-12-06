
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
    self.householdNameLabel.text = @"N/A";
    Household *household = [User currentUser].activeHousehold;
    [household fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            self.householdNameLabel.text = household[@"householdName"];
        } else {
            [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
        }
    }];
}


@end
