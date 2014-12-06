#import "SuperViewController.h"
#import "LoginViewController.h"
#import "User.h"

@interface SuperViewController ()

@end

@implementation SuperViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![User isAnyoneLoggedIn]) {
        [self presentLoginScreen];
    }
}

- (void)presentLoginScreen {
    LoginViewController *notLoggedInVC = [self.storyboard instantiateViewControllerWithIdentifier:@"NotLoggedInView"];
    [self presentViewController:notLoggedInVC animated:YES completion:nil];
}

@end
