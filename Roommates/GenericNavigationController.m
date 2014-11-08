
#import "GenericNavigationController.h"
#import "User.h"

@interface GenericNavigationController ()

@end

@implementation GenericNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationBar.backgroundColor = [UIColor whiteColor];
    self.navigationBar.translucent = NO;
    
    [[User currentUser] fetchInBackground];
}

@end
