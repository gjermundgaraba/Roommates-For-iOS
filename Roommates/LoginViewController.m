
#import "LoginViewController.h"
#import "SignupViewController.h"
#import <Parse/Parse.h>
#import "SVProgressHUD.h"
#import "User.h"

@interface LoginViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@end

@implementation LoginViewController

/** If the user is already logged in, it will dismiss this viewcontroller **/

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([User currentUser]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

/** Changes statusbar color to white **/

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark Button actions

/**  When Logging in, show progressHUD, remove keyboard. Shows a UIAlertView if error **/

- (IBAction)login {
    // Remove keyboard
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    
    // Get username and password from Views
    NSString *username = self.usernameTextField.text;
    NSString *password = self.passwordTextField.text;
    
    // Check if fields are filled out
    if ([username isEqualToString:@""] || [password isEqualToString:@""]) {
        UIAlertView *emptyFieldsAlert = [[UIAlertView alloc] initWithTitle:@"Could not log in"
                                                             message:@"Please fill out username and password"
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
        [emptyFieldsAlert show];
    }
    else {
        // Start login process (with parse):
        [SVProgressHUD showWithStatus:@"Logging in" maskType:SVProgressHUDMaskTypeBlack];
        [User logInWithUsernameInBackground:username
                                   password:password
                                      block:^(PFUser *user, NSError *error)
         {
             // Done, time to check if things went OK
             [SVProgressHUD dismiss];
             if (!error) { // ok !
                 [User refreshChannels]; // Update Push
                 
                 // Remove login screen and show the app
                 [self dismissViewControllerAnimated:YES completion:nil];
             }
             else { // not ok...
                 UIAlertView *loginFailAlert = [[UIAlertView alloc] initWithTitle:@"Could not log in"
                                                                      message:@""
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                 
                 if (error.code == kPFErrorObjectNotFound) {
                     loginFailAlert.message = @"Username Password Combination is Wrong";
                 }
                 else {
                     loginFailAlert.message = @"Something went wrong";
                 }
                 
                 [loginFailAlert show];
             }
         }];
    }
}

/**  When Logging in with fb, show progressHUD, remove keyboards. Shows a UIAlertView if error **/

- (IBAction)loginWithFacebbok  {
    [SVProgressHUD showWithStatus:@"Logging in" maskType:SVProgressHUDMaskTypeBlack];
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
 
    
    // The permissions requested from the user
    NSArray *permissionsArray = @[ @"email" ];
    
    // Login PFUser using Facebook
    [PFFacebookUtils logInWithPermissions:permissionsArray
                                    block:^(PFUser *user, NSError *error)
    {
         [SVProgressHUD dismiss];
         // Check if something went wrong
         if (!error) {
             if (user) {
                 [User refreshChannels];
                 
                 if (user.isNew) {
                     FBRequest *request = [FBRequest requestForMe];
                     
                     // Send request to Facebook for user information
                     [SVProgressHUD showWithStatus:@"Getting data from Facebook" maskType:SVProgressHUDMaskTypeBlack];
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
                              
                              user[@"username"] = userData[@"email"];
                              user[@"displayName"] = userData[@"name"];
                              user[@"email"] = userData[@"email"];
                              
                              NSData *pictureData = [NSData dataWithContentsOfURL:pictureURL];
                              UIImage *profilePicture = [UIImage imageWithData:pictureData];
                              
                              
                              NSData *imageData = UIImagePNGRepresentation(profilePicture);
                              PFFile *pictureFile = [PFFile fileWithData:imageData];
                              user[@"profilePicture"] = pictureFile;
                              
                              [user saveInBackground];
                              
                              [SVProgressHUD dismiss];
                              [self dismissViewControllerAnimated:YES completion:nil];
                          }
                          else {
                              [PFUser logOut];
                              [user deleteInBackground];
                              UIAlertView *facebookFailAlert = [[UIAlertView alloc] initWithTitle:@"Could not sign up" message:@"Could not contact Facebook, please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                              [facebookFailAlert show];
                          }
                      }];
                 }
                 else {
                     [self dismissViewControllerAnimated:YES completion:nil];
                 }
             } // end if (user)
         } // end if (!error)
         else {
             // Something went wrong
             int errorCode = error.code;
             NSString *errorString = [NSString stringWithFormat:@"Error code: %d. Something went wrong, please try again.", errorCode];
             
             if (errorCode == kPFErrorConnectionFailed) {
                 errorString = @"The Internet connection appears to be offline.";
             }
             
             UIAlertView *facebookLoginFailAlert = [[UIAlertView alloc] initWithTitle:@"Could not log in."
                                                                              message:errorString
                                                                             delegate:nil
                                                                    cancelButtonTitle:@"OK"
                                                                    otherButtonTitles:nil];
             [facebookLoginFailAlert show];
         }
     }];
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
