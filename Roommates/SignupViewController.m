
#import "SignupViewController.h"
#import <Parse/Parse.h>
#import "SVProgressHUD.h"
#import "InputValidation.h"
#import "User.h"

#define usernameTextFieldDistance 55
#define emailTextFieldDistance 110
#define passwordTextFieldDistance 165
#define repeatedPasswordTextFieldDistance 220

@interface SignupViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *displayNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *repeatedPasswordTextField;
@end

@implementation SignupViewController

/** Changes statusbar color to white **/

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

/** Registrating user in background, progressHUD showing. If error the UIAlertView is showing **/
- (IBAction)register {
    NSString *displayName = self.displayNameTextField.text;
    NSString *email = [[self.emailTextField.text lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *password = self.passwordTextField.text;
    NSString *repeatedPassword = self.repeatedPasswordTextField.text;
    
    
    
    // Check the validity of the input from the user
    UIAlertView *invalidAlert = [[UIAlertView alloc] initWithTitle:@"Could not sign up"
                                                           message:@""
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
    if (![InputValidation validateEmail:email]) {
        invalidAlert.message = @"Email is not valid";
        [invalidAlert show];
    }
    else if (![InputValidation validateName:displayName]) {
        invalidAlert.message = @"Display Name is not valid";
        [invalidAlert show];
    }
    else if (![InputValidation validatePassword:password]) {
        invalidAlert.message = @"Password is not valid. A Valid password needs to be at least 6 characters long, have at least one upper and one lower case letters and at least one number";
        [invalidAlert show];
    }
    else if (![password isEqualToString:repeatedPassword]) {
        invalidAlert.message = @"Passwords do not match";
        [invalidAlert show];
    }
    else {
        // Everything should be ok, so we make a new user.
        User *newUser = [User user];
        newUser.username = email;
        newUser.password = password;
        newUser.email = email;
        newUser.displayName = displayName;
        [SVProgressHUD showWithStatus:@"Signing up..." maskType:SVProgressHUDMaskTypeBlack];
        [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [SVProgressHUD dismiss];
            if (!error) {
                // User created, time to log him in
                [SVProgressHUD showWithStatus:@"Logging in..." maskType:SVProgressHUDMaskTypeBlack];
                [User logInWithUsernameInBackground:email password:password block:^(User *user, NSError *error) {
                    // User is logged in, now we let him into the app
                    [SVProgressHUD dismiss];
                    if (!error) {
                        [User refreshChannels];
                        [self performSegueWithIdentifier:@"signUpUnwind" sender:self];
                    }
                    else {
                        // Log in failed, sign in manually
                        UIAlertView *signInAlert = [[UIAlertView alloc] initWithTitle:@"Could log in"
                                                                              message:@"User registered, but could not automatically sign in."
                                                                             delegate:nil
                                                                    cancelButtonTitle:@"OK"
                                                                    otherButtonTitles:nil];
                        [signInAlert show];
                    }
                }];
            }
            else {
                // Sign up failed for some reason, tell the user
                
                NSString *errorString = [NSString stringWithFormat:@"Error code: %ld. Something went wrong, please try again.", error.code];
                
                if (error.code == kPFErrorConnectionFailed) {
                    errorString = @"The Internet connection appears to be offline.";
                }
                else if (error.code == kPFErrorUsernameTaken) {
                    errorString = @"Username already taken";
                }

                UIAlertView *signUpAlert = [[UIAlertView alloc] initWithTitle:@"Could not sign up"
                                                                      message:errorString
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                [signUpAlert show];
            }
        }];
    }
}


#pragma mark UITextField animation


//TODO: FIX ALL THE ANIMATION THINGY AFTER TESTING
- (int)getDistanceForTextField:(UITextField *)textField {
    int distance = 80;
    
    /*
    if (textField == self.firstnameTextField) distance = firstnameTextFieldDistance;
    else if (textField == self.lastnameTextField) distance = lastnameTextFieldDistance;
    else if (textField == self.usernameTextField) distance = usernameTextFieldDistance;
    else if (textField == self.emailTextField) distance = emailTextFieldDistance;
    else if (textField == self.passwordTextField) distance = passwordTextFieldDistance;
    else if (textField == self.repeatedPasswordTextField) distance = repeatedPasswordTextFieldDistance;
     */
    
    return distance;
}

/** Animating the textFields to fit with keyboard on screen with support for ipad **/

- (void) animateTextField:(UITextField*)textField up:(BOOL)up distance:(int)distance
{
    int movementDistance = distance; // tweak as needed
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

/** Lets us know when textfield events happen, move the view when keyboard pops up **/

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    int distance = [self getDistanceForTextField:textField];
    [self animateTextField:textField up:YES distance:distance];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    int distance = [self getDistanceForTextField:textField];
    [self animateTextField:textField up:NO distance:distance];
}

// Done, remove keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

/** Prepares for segue into the app  **/

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

}



@end
