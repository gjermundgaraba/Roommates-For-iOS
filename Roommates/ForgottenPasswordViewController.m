
#import "ForgottenPasswordViewController.h"
#import "User.h"
#import "SVProgressHUD.h"

@interface ForgottenPasswordViewController () <UIAlertViewDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIButton *resetPasswordButton;
@end

@implementation ForgottenPasswordViewController

/** Changes statusbar color to white **/

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

/** When the user presses OK in the sucessalertview, a segue will transfer the user back to log in screen **/

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self performSegueWithIdentifier:@"forgotUnwind" sender:nil];
}

/** resets password in background, if sucess sucessalertview. If not sucess error alertview.**/

- (IBAction)resetPassword:(id)sender {
    NSString *email = self.emailTextField.text;
    
    if ([email isEqualToString:@""]) {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Could not reset password"
                                                             message:@"You must enter an email!"
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
        [errorAlert show];
    }
    else {
        [SVProgressHUD showWithStatus:@"Resetting Password..." maskType:SVProgressHUDMaskTypeBlack];
        [User requestPasswordResetForEmailInBackground:email
                                                   block:^(BOOL succeeded, NSError *error)
         {
             [SVProgressHUD dismiss];
             if (!error) {
                 UIAlertView *emailSetAlert = [[UIAlertView alloc] initWithTitle:@"Success!"
                                                                         message:@"An email has been sent with instructions to reset your password"
                                                                        delegate:self
                                                               cancelButtonTitle:@"OK"
                                                               otherButtonTitles:nil];
                 [emailSetAlert show];
             }
             else {
                 UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Could not reset password"
                                                                      message:error.userInfo[@"error"]
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                 [errorAlert show];
             }
         }];
        
    }
}

#pragma mark UITextField animation

/** Animating the textFields to fit with keyboard on screen with support for ipad **/

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self animateTextField:textField up:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self animateTextField:textField up:NO];
}

- (void) animateTextField: (UITextField*) textField up: (BOOL) up {
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

/** Lets us know when textfieldevents happen **/

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}
@end
