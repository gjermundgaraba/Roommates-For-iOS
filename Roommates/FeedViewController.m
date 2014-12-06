
#import "FeedViewController.h"
#import "Note.h"
#import "User.h"
#import "SVProgressHUD.h"

@interface FeedViewController () <UIAlertViewDelegate>
@end

static int ADD_BUTTON_INDEX = 1;

@implementation FeedViewController


- (IBAction)addNote:(id)sender {
    if ([[User currentUser] isMemberOfAHousehold]) {
        UIAlertView *newNoteAlert = [[UIAlertView alloc] initWithTitle:@"New Note"
                                                               message:@""
                                                              delegate:self
                                                     cancelButtonTitle:@"Cancel"
                                                     otherButtonTitles:@"OK", nil];
        newNoteAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [newNoteAlert textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
        [newNoteAlert show];
    } else {
        [SVProgressHUD showErrorWithStatus:@"Not member of a household! Go to Me->Household Settings."];
    }
}

- (void)createNewNote:(Note *)newNote {
    [SVProgressHUD showWithStatus:@"Creating new Note"];
    [newNote saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [SVProgressHUD dismiss];
        if (!error) {
            [SVProgressHUD showSuccessWithStatus:@"Note Created!"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NewNoteCreated" object:nil];
        } else {
            [SVProgressHUD showErrorWithStatus:error.userInfo[@"error"]];
        }
    }];
}

#pragma mark UIAlertView Delegate Methods

// Add note
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == ADD_BUTTON_INDEX) {
        PFACL *acl = [PFACL ACL];
        [acl setReadAccess:YES forRoleWithName:[User currentUser].householdChannel];
        
        Note *newNote = [Note object];
        newNote.createdBy = [User currentUser];
        newNote.body = [alertView textFieldAtIndex:0].text;
        newNote.household = [User currentUser].activeHousehold;
        newNote.ACL = acl;
        
        [self createNewNote:newNote];
    }
}

@end
