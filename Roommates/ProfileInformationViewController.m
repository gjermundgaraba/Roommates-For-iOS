
#import "ProfileInformationViewController.h"
#import <Parse/Parse.h>
#import "SVProgressHUD.h"
#import "InputValidation.h"
#import "User.h"

@interface ProfileInformationViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIPopoverControllerDelegate, UIActionSheetDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet PFImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextField *displayNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordTextField;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;

@property User *currentUser;
@end

@implementation ProfileInformationViewController

#pragma mark View Controller Life Cycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set us up as text field delegates
    self.displayNameTextField.delegate = self;
    self.emailTextField.delegate = self;
    self.confirmPasswordTextField.delegate = self;
    
    // Set up the text field data
    self.displayNameTextField.text = self.currentUser.displayName;
    self.emailTextField.text = self.currentUser.email;
    
    // Dont need it enabled before something actually changes...
    self.saveButton.enabled = NO;
    
    // Set up Image View for interaction and to look pretty
    self.imageView.userInteractionEnabled = YES;
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.cornerRadius = self.imageView.frame.size.height / 2;
    self.imageView.layer.borderWidth = 3.0f;
    self.imageView.layer.borderColor = [UIColor grayColor].CGColor;
    self.imageView.layer.masksToBounds = YES;
    
    // Sets the profile picture as the image view picture and load it
    // Thx Parse! :D
    PFFile *profilePicture = self.currentUser.profilePicture;
    self.imageView.image = [UIImage imageNamed:@"placeholder"];
    self.imageView.file = profilePicture;
    [self.imageView loadInBackground];
}

#pragma mark getters and setters

- (User *)currentUser {
    return [User currentUser];
}

- (void)setCurrentUser:(User *)currentUser {}

#pragma mark Image Switching Methods

- (void)chooseProfilePicture:(UIImagePickerControllerSourceType)source {
    //sets up imagepicker which lets you choose a picture
    if([UIImagePickerController isSourceTypeAvailable:source])
    {
        UIImagePickerController *imagePicker=nil;
        imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.AllowsEditing = YES;
        imagePicker.delegate = self;
        imagePicker.sourceType = source;
        
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Source not supported"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        
    }
}

- (IBAction)profilePictureClicked:(id)sender {
    //sets up uiactionsheet
    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Change Profile Picture:"
                                                       delegate:self cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Picture from Camera Roll",
                                                                @"Take a New Picture",
                                                                nil];
    [popup showInView:[UIApplication sharedApplication].keyWindow];
}


#pragma mark User Information Methods

- (IBAction)saveChangesButtonPressed {
    NSString *oldDisplayName = self.currentUser.displayName;
    NSString *oldEmail = self.currentUser.email;
    
    NSString *displayName = self.displayNameTextField.text;
    NSString *email = [[self.emailTextField.text lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *confirmPassword = self.confirmPasswordTextField.text;
    
    BOOL displayNameChanged = ![displayName isEqualToString:oldDisplayName];
    BOOL emailChanged = ![email isEqualToString:oldEmail];
    
    //Changes displayname and email in background
    if (displayNameChanged || emailChanged) {
        if (![InputValidation validateName:displayName]) {
            UIAlertView *invalidDisplayNameAlert = [[UIAlertView alloc] initWithTitle:@"Could not change user info." message:@"Display Name is not valid." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [invalidDisplayNameAlert show];
        }
        else if (![InputValidation validateEmail:email]) {
            UIAlertView *invalidEmailAlert = [[UIAlertView alloc] initWithTitle:@"Could not change user info." message:@"Email is not valid." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [invalidEmailAlert show];
        }
        else {
            [SVProgressHUD showWithStatus:@"Checking Password" maskType:SVProgressHUDMaskTypeBlack];
            [User logInWithUsernameInBackground:self.currentUser.username password:confirmPassword block:^(User *user, NSError *error) {
                [SVProgressHUD dismiss];
                if (!error) {
                    self.currentUser.username = email;
                    self.currentUser.email = email;
                    self.currentUser.displayName = displayName;
                    
                    [SVProgressHUD showWithStatus:@"Chaning user info" maskType:SVProgressHUDMaskTypeBlack];
                    [self.currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        [SVProgressHUD dismiss];
                        if (!error) {
                            UIAlertView *successChangeAlert = [[UIAlertView alloc] initWithTitle:@"User info changed" message:@"User info was successfully changed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                            [successChangeAlert show];
                            [self.navigationController popToRootViewControllerAnimated:YES];
                        }
                        else {
                            // Reset user to old stuff
                            self.currentUser.username = oldEmail;
                            self.currentUser.email = oldEmail;
                            self.currentUser.displayName = displayName;
                            
                            UIAlertView *errorChangeAlert = [[UIAlertView alloc] initWithTitle:@"User info not changed" message:error.userInfo[@"error"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                            [errorChangeAlert show];
                        }
                    }];
                }
                else {
                    UIAlertView *wrongPasswordAlert = [[UIAlertView alloc] initWithTitle:@"Could not change user info." message:@"Password was not correct. Try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [wrongPasswordAlert show];
                }
            }];
        }
    }
}



#pragma mark ImagePicker Delegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    //saving profilepicture in background when new profilepicture is picked
    
    [SVProgressHUD showWithStatus:@"Saving Profile Picture to Server" maskType:SVProgressHUDMaskTypeBlack];
    
    UIGraphicsBeginImageContext(CGSizeMake(200, 200));
    [image drawInRect: CGRectMake(0, 0, 200, 200)];
    UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *imageData = UIImagePNGRepresentation(smallImage);
    PFFile *pictureFile = [PFFile fileWithData:imageData];
    PFFile *oldProfilePicture = self.currentUser.profilePicture;
    self.currentUser.profilePicture = pictureFile;
    [self.currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [SVProgressHUD dismiss];
        if (!error) {
            [SVProgressHUD showSuccessWithStatus:@"Profile Picture Saved!"];
            self.imageView.image = image;
        }
        else {
            UIAlertView *imageSaveFailAlert = [[UIAlertView alloc] initWithTitle:@"Failed to save Profile Picture" message:error.userInfo[@"error"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            self.currentUser.profilePicture = oldProfilePicture;
            [imageSaveFailAlert show];
            
        }
    }];
}




#pragma mark UIActionSheet Delegate Methods

//lets us know the behaviour of the actionsheet
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self chooseProfilePicture:UIImagePickerControllerSourceTypePhotoLibrary];
            break;
        case 1:
            [self chooseProfilePicture:UIImagePickerControllerSourceTypeCamera];
            break;
        default:
            break;
    }
}

#pragma mark UITextField animation

/** Animating the textFields to fit with keyboard on screen with support for ipad **/

- (void) animateTextField: (UITextField*) textField up: (BOOL) up {
    const int movementDistance = 120; // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}


#pragma mark UITextField Delegate Methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.saveButton.enabled = YES;
    [self animateTextField:textField up:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self animateTextField:textField up:NO];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
