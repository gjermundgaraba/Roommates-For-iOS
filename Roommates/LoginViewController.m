
#import "LoginViewController.h"
#import "SignupViewController.h"
#import <Parse/Parse.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import "SVProgressHUD.h"
#import "User.h"

@interface LoginViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@end

@implementation LoginViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([User isAnyoneLoggedIn]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark Button actions

- (IBAction)login {
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    
    NSString *username = self.usernameTextField.text;
    NSString *password = self.passwordTextField.text;
    
    if ([username isEqualToString:@""] || [password isEqualToString:@""]) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Please fill out username and password", nil)];
    } else {
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Logging in", nil) maskType:SVProgressHUDMaskTypeBlack];
        [User logInWithUsernameInBackground:username
                                   password:password
                                      block:^(PFUser *user, NSError *error)
         {
             [SVProgressHUD dismiss];
             if (!error) {
                 [User refreshChannels];
                 [[NSNotificationCenter defaultCenter] postNotificationName:@"ResetHouseholdScenes" object:nil];
                 [self dismissViewControllerAnimated:YES completion:nil];
             } else {
                 if (error.code == kPFErrorObjectNotFound) {
                     [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Username Password Combination is Wrong", nil)];
                 } else {
                     [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Something went wrong", nil)];
                 }
             }
         }];
    }
}

- (IBAction)loginWithFacebbok  {
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Logging in", nil) maskType:SVProgressHUDMaskTypeBlack];
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    
    NSArray *permissionsArray = @[ @"email" ];
    [PFFacebookUtils logInWithPermissions:permissionsArray
                                    block:^(PFUser *user, NSError *error)
    {
         [SVProgressHUD dismiss];
         if (!error) {
             if (user) {
                 [User refreshChannels];
                 
                 if (user.isNew) {
                     FBRequest *request = [FBRequest requestForMe];
                     
                     [SVProgressHUD showWithStatus:NSLocalizedString(@"Getting data from Facebook", nil) maskType:SVProgressHUDMaskTypeBlack];
                     [request startWithCompletionHandler:^(FBRequestConnection *connection,
                                                           id result,
                                                           NSError *error)
                      {
                          if (!error) {
                              NSDictionary *userData = (NSDictionary *)result;
                              NSString *fbPictureURL =
                              @"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1";
                              
                              NSString *facebookID = userData[@"id"];
                              NSURL *pictureURL = [NSURL URLWithString:
                                                   [NSString stringWithFormat:fbPictureURL, facebookID]];
                              
                              NSData *pictureData = [NSData dataWithContentsOfURL:pictureURL];
                              UIImage *profilePicture = [UIImage imageWithData:pictureData];
                              NSData *imageData = UIImagePNGRepresentation(profilePicture);
                              PFFile *pictureFile = [PFFile fileWithData:imageData];
                              
                              user[@"username"] = userData[@"email"];
                              user[@"displayName"] = userData[@"name"];
                              user[@"email"] = userData[@"email"];
                              user[@"profilePicture"] = pictureFile;
                              
                              [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                  [SVProgressHUD dismiss];
                                  if (!error) {
                                      [self dismissViewControllerAnimated:YES completion:nil];
                                  } else {
                                      [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
                                      [user deleteInBackground];
                                      //[PFUser logOut];
                                  }
                              }];
                          } else {
                              [SVProgressHUD dismiss];
                              [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Could not contact Facebook, please try again later.", nil)];
                              [user deleteInBackground];
                          }
                      }];
                 } else {
                     [[NSNotificationCenter defaultCenter] postNotificationName:@"ResetHouseholdScenes" object:nil];
                     [self dismissViewControllerAnimated:YES completion:nil];
                 }
             }
         } else {
             [self handleAuthError:error];
         }
     }];
}

- (void)handleAuthError:(NSError *)error
{
    if ([FBErrorUtility shouldNotifyUserForError:error] == YES){
        [SVProgressHUD showErrorWithStatus:[FBErrorUtility userMessageForError:error]];
        
    } else {
        // You need to find more information to handle the error within your app
        if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
            [SVProgressHUD showErrorWithStatus:@"You need to login to access this part of the app"];
            
        } else {
            [SVProgressHUD showErrorWithStatus:@"Something went wrong, please retry"];
        }
    }
}

#pragma mark UITextField animation

/** Animating the textFields to fit with keyboard on screen **/

- (void) animateTextField: (UITextField*) textField up: (BOOL) up
{
    const int movementDistance = 80; // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (orientation ==  UIDeviceOrientationPortrait)
    {
        self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    }
    else {
        self.view.frame = CGRectOffset(self.view.frame, -movement, 0);
    }
    [UIView commitAnimations];
}


#pragma mark UITextField Delegate methods

/** Lets us know when textfieldevents happen **/

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self animateTextField:textField up:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self animateTextField:textField up:NO];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

// Needs to be here for unwind segue...
- (IBAction)unwindToLogin:(UIStoryboardSegue *)unwindSegue {}


@end
