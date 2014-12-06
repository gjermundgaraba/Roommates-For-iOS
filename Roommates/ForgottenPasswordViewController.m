
#import "ForgottenPasswordViewController.h"
#import "User.h"
#import "SVProgressHUD.h"

@interface ForgottenPasswordViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIButton *resetPasswordButton;
@end

@implementation ForgottenPasswordViewController

/** Changes statusbar color to white **/

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (IBAction)resetPassword:(id)sender {
    NSString *email = self.emailTextField.text;
    
    if ([email isEqualToString:@""]) {
        [SVProgressHUD showErrorWithStatus:@"You must enter an email!"];
    }
    else {
        [SVProgressHUD showWithStatus:@"Resetting Password..." maskType:SVProgressHUDMaskTypeBlack];
        [User requestPasswordResetForEmailInBackground:email
                                                   block:^(BOOL succeeded, NSError *error)
         {
             [SVProgressHUD dismiss];
             if (!error) {
                 [SVProgressHUD showSuccessWithStatus:@"An email has been sent with instructions to reset your password"];
                 [self performSegueWithIdentifier:@"forgotUnwind" sender:nil];
             }
             else {
                 [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
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
