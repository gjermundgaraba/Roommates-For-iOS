
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
    
    
    if (![InputValidation validateEmail:email]) {
        [SVProgressHUD showErrorWithStatus:@"Email is not valid"];
    }
    else if (![InputValidation validateName:displayName]) {
        [SVProgressHUD showErrorWithStatus:@"Display Name is not valid"];
    }
    else if (![InputValidation validatePassword:password]) {
        [SVProgressHUD showErrorWithStatus:@"Password is not valid. A Valid password needs to be at least 6 characters long, have at least one upper and one lower case letters and at least one number"];
    }
    else if (![password isEqualToString:repeatedPassword]) {
        [SVProgressHUD showErrorWithStatus:@"Passwords do not match"];
    }
    else {
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
                    [SVProgressHUD dismiss];
                    if (!error) {
                        [User refreshChannels];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"ResetHouseholdScenes" object:nil];
                        [self performSegueWithIdentifier:@"signUpUnwind" sender:self];
                    }
                    else {
                        [SVProgressHUD showErrorWithStatus:@"User registered, but could not automatically sign in."];
                    }
                }];
            }
            else {
                [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

}



@end
