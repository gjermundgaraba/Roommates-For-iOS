//
//  User.m
//  Roommates
//
//  Created by Gjermund Bjaanes on 16/04/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import "User.h"
#import <Parse/PFObject+Subclass.h>
#import "Installation.h"

@implementation User

@dynamic activeHousehold;
@dynamic displayName;
@dynamic profilePicture;

- (NSString *)userChannel {
    return [NSString stringWithFormat:@"user-%@", self.objectId];
}

- (NSString *)householdChannel {
    if ([self isMemberOfAHousehold]) {
        Household *household = self.activeHousehold;
        return [NSString stringWithFormat:@"household-%@", household.objectId];
    }
    else {
        return nil;
    }
}


- (BOOL)isMemberOfAHousehold {
    return self.activeHousehold ? YES : NO;
}

+ (NSString *)parseClassName {
    return @"_User";
}

+ (void)logInWithUsernameInBackground:(NSString *)username password:(NSString *)password block:(void (^)(User *user, NSError *error))block {
    [PFUser logInWithUsernameInBackground:username
                                 password:password
                                    block:^(PFUser *user, NSError *error)
    {
        block((User *)user, error);
    }];
}

+ (User *)user {
    return (User *)[PFUser user];
}

+ (User *)currentUser {
    return (User *)[PFUser currentUser];
}

+ (void)refreshChannels {
    Installation *currentInstallation = [Installation currentInstallation];
    
    User *currentUser = [User currentUser];
    
    // Start by remove all channels
    [currentInstallation reset];
    
    // Set up empty ACL
    PFACL *defaultACL = [PFACL ACL];
    
    if (currentUser) {
        // If logged in, add user channel
        currentInstallation.user = currentUser;
        
        if ([currentUser isMemberOfAHousehold]) {
            // Set up default ACL
            
            NSString *roleName = currentUser.householdChannel;
            [defaultACL setReadAccess:YES forRoleWithName:roleName];
            [defaultACL setWriteAccess:YES forRoleWithName:roleName];
            
            currentInstallation.household = currentUser.activeHousehold;
        }
    }
    
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:NO];
    [currentInstallation saveEventually];
}

@end
