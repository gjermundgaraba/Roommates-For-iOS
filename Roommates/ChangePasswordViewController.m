
#import "ChangePasswordViewController.h"
#import <Parse/Parse.h>
#import "SVProgressHUD.h"
#import "InputValidation.h"
#import "User.h"

@interface ChangePasswordViewController ()
@property (weak, nonatomic) IBOutlet UITextField *oldPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *changePasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *confirmNewPasswordTextField;

@end

@implementation ChangePasswordViewController

- (IBAction)changeNameButtonPush {
    NSString *oldPassword = self.oldPasswordTextField.text;
    NSString *changePassword = self.changePasswordTextField.text;
    NSString *confirmPassword = self.confirmNewPasswordTextField.text;
    
    if ([self.oldPasswordTextField.text isEqualToString:@""] ||
        [self.changePasswordTextField.text isEqualToString:@""] ||
        [self.confirmNewPasswordTextField.text isEqualToString:@""]) {
        [SVProgressHUD showErrorWithStatus:@"Please fill out all fields"];
    }
    else if (![changePassword isEqualToString:confirmPassword]) {
        [SVProgressHUD showErrorWithStatus:@"Passwords do not match!"];
    }
    else if (![InputValidation validatePassword:changePassword]) {
        [SVProgressHUD showErrorWithStatus:@"Password is not valid. A Valid password needs to be at least 6 characters long, have at least one upper and one lower case letters and at least one number"];
    }
    else {
        [SVProgressHUD showWithStatus:@"Changing password..." maskType:SVProgressHUDMaskTypeBlack];
        User *user = [User currentUser];
        [User logInWithUsernameInBackground:user.username password:oldPassword block:^(User *user, NSError *error) {
            [SVProgressHUD dismiss];
            if (!error) {
                user.password = changePassword;
                [SVProgressHUD showWithStatus:@"Saving.." maskType:SVProgressHUDMaskTypeBlack];
                [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    [SVProgressHUD dismiss];
                    if (!error) {
                        [SVProgressHUD showSuccessWithStatus:@"User has been updated!"];
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                    else {
                        [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
                    }
                }];
            }
            else {
                [SVProgressHUD showErrorWithStatus:@"Password is incorrect"];
            }
        }];
    }
}

#pragma mark UITextField animation


- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self animateTextField:textField up:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self animateTextField:textField up:NO];
}

- (void) animateTextField: (UITextField*) textField up: (BOOL) up
{
    const int movementDistance = 80; // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}

#pragma mark UITextField Delegate methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}


@end
