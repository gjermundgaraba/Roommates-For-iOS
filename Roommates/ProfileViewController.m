
#import "ProfileViewController.h"
#import "LoginViewController.h"
#import <Parse/Parse.h>
#import "User.h"

@interface ProfileViewController ()
@property (weak, nonatomic) IBOutlet PFImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property User *currentUser;
@end

@implementation ProfileViewController

#pragma mark setters and getters

// Gets the user from static call
- (User *)currentUser {
    return [User currentUser];
}

// Supposed to be empty, Just in case someone tries to set it (they need not, and should not)
- (void)setCurrentUser:(User *)currentUser {}

#pragma mark View Controller Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Set up profile picture layout (round with border)
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.cornerRadius = self.imageView.frame.size.height / 2; // Round
    self.imageView.layer.borderWidth = 3.0f;
    self.imageView.layer.borderColor = [UIColor grayColor].CGColor;
    self.imageView.layer.masksToBounds = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Get and load the profile picture
    self.imageView.image = [UIImage imageNamed:@"placeholder"];
    self.imageView.file = self.currentUser.profilePicture;
    
    //sets up to show the users displayname in the view, next to the profile picture
    self.nameLabel.text = self.currentUser.displayName;
    
    [self.imageView loadInBackground];
}

@end
