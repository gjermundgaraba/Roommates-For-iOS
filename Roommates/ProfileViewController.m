
#import "ProfileViewController.h"
#import "LoginViewController.h"
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "User.h"

@interface ProfileViewController ()
@property (weak, nonatomic) IBOutlet PFImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property User *currentUser;
@end

@implementation ProfileViewController

#pragma mark setters and getters

- (User *)currentUser {
    return [User currentUser];
}

- (void)setCurrentUser:(User *)currentUser {}

#pragma mark View Controller Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.cornerRadius = self.imageView.frame.size.height / 2;
    self.imageView.layer.masksToBounds = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.imageView.image = [UIImage imageNamed:@"placeholder"];
    self.imageView.file = self.currentUser.profilePicture;
    [self.imageView loadInBackground];
    self.nameLabel.text = self.currentUser.displayName;
}

@end
