//
//  ChangePasswordViewController.m
//  Roommates
//
//  Created by Gjermund Bjaanes on 07/03/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//
//  TODO: needs commenting

#import "ChangePasswordViewController.h"
#import <Parse/Parse.h>
#import "SVProgressHUD.h"
#import "InputValidation.h"
#import "User.h"

@interface ChangePasswordViewController () <UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *oldPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *changePasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *confirmNewPasswordTextField;
@property (weak, nonatomic) IBOutlet UIButton *changeButton;

@end

@implementation ChangePasswordViewController

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)changeNameButtonPush {
    NSString *oldPassword = self.oldPasswordTextField.text;
    NSString *changePassword = self.changePasswordTextField.text;
    NSString *confirmPassword = self.confirmNewPasswordTextField.text;
    
    if ([self.oldPasswordTextField.text isEqualToString:@""] ||
        [self.changePasswordTextField.text isEqualToString:@""] ||
        [self.confirmNewPasswordTextField.text isEqualToString:@""]) {
        UIAlertView *emptyAlert = [[UIAlertView alloc] initWithTitle:@"Empty fields" message:@"Fill out the fields" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [emptyAlert show];
    }
    else if (![changePassword isEqualToString:confirmPassword]) {
        UIAlertView *notEqualAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Passwords do not match!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [notEqualAlert show];
    }
    else if (![InputValidation validatePassword:changePassword]) {
        UIAlertView *invalidAlert = [[UIAlertView alloc] initWithTitle:@"Invalid Password" message:@"Password is not valid. A Valid password needs to be at least 6 characters long, have at least one upper and one lower case letters and at least one number" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [invalidAlert show];
    }
    else {
        [SVProgressHUD showWithStatus:@"Changing password..." maskType:SVProgressHUDMaskTypeBlack];
        [self.changeButton setEnabled:NO];
        User *user = [User currentUser];
        [User logInWithUsernameInBackground:user.username password:oldPassword block:^(User *user, NSError *error) {
            if (!error) {
                user.password = changePassword;
                
                [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    [SVProgressHUD dismiss];
                    [self.changeButton setEnabled:YES];
                    if (!error) {
                        UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"User has been updated!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [successAlert show];
                    }
                    else {
                        NSString *errorString = [error userInfo][@"error"];
                        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [errorAlert show];
                    }
                }];
            }
            else {
                [SVProgressHUD dismiss];
                [self.changeButton setEnabled:YES];
                UIAlertView *wrongPasswordAlert = [[UIAlertView alloc] initWithTitle:@"Wrong Password" message:@"The password you provided was incorrect" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [wrongPasswordAlert show];
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
