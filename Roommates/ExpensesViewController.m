
#import "ExpensesViewController.h"
#import "User.h"
#import "SVProgressHUD.h"

@interface ExpensesViewController ()

@end

@implementation ExpensesViewController

- (IBAction)addButtonPushed:(id)sender {
    if ([[User currentUser] isMemberOfAHousehold]) {
        [self performSegueWithIdentifier:@"addExpenseSegue" sender:nil];
    } else {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Not member of a household! Go to Me->Household Settings.", nil)];
    }
    
}

@end
