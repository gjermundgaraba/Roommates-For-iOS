//
//  SuperViewController.m
//  Roommates
//
//  Created by Gjermund Bjaanes on 19/02/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import "SuperViewController.h"
#import "LoginViewController.h"
#import "User.h"

@interface SuperViewController ()

@end

@implementation SuperViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Check if there is a user logged in
    if (![User currentUser]) {
        // If no, present the login screen
        //[self.tabBarController setSelectedIndex:0];
        LoginViewController *notLoggedInVC =
                [self.storyboard instantiateViewControllerWithIdentifier:@"NotLoggedInView"];
        [self presentViewController:notLoggedInVC animated:YES completion:nil];
    }
}

@end
