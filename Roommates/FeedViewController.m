//
//  FeedViewController.m
//  Roommates
//
//  Created by Gjermund Bjaanes on 06/03/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//
// Only holds two containers that does all the work
// (feed and notes)


#import "FeedViewController.h"
#import "Note.h"
#import "User.h"
#import "SVProgressHUD.h"

@interface FeedViewController () <UIAlertViewDelegate>
@end

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
    }
}

#pragma mark UIAlertView Delegate Methods

// Add note
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // User pressed Add
        PFACL *acl = [PFACL ACL];
        [acl setReadAccess:YES forRoleWithName:[User currentUser].householdChannel];
        
        Note *newNote = [Note object];
        newNote.createdBy = [User currentUser];
        newNote.body = [alertView textFieldAtIndex:0].text;
        newNote.household = [User currentUser].activeHousehold;
        newNote.ACL = acl;
        
        [SVProgressHUD showWithStatus:@"Creating new Note"];
        [newNote saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [SVProgressHUD dismiss];
            if (!error) {
                [SVProgressHUD showSuccessWithStatus:@"Note Created!"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"NewNoteCreated" object:nil];
            }
            else {
                UIAlertView *saveNoteFailAlert = [[UIAlertView alloc] initWithTitle:@"Could not create new note" message:error.userInfo[@"error"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [saveNoteFailAlert show];
            }
        }];
    }
}

@end
