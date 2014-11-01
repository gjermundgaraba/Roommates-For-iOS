//
//  User.h
//  Roommates
//
//  Created by Gjermund Bjaanes on 16/04/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import <Parse/Parse.h>
#import "Household.h"

@interface User : PFUser <PFSubclassing>

@property Household *activeHousehold;
@property NSString *displayName;
@property PFFile *profilePicture;

@property (readonly) NSString *userChannel;
@property (readonly) NSString *householdChannel;

// Check if user is member of a household
- (BOOL)isMemberOfAHousehold;

+ (NSString *)parseClassName;

// Override to return a User * instead of a PFUser *
+ (void)logInWithUsernameInBackground:(NSString *)username password:(NSString *)password block:(void (^)(User *user, NSError *error))block;

// Override to return a User * instead of a PFUser *
+ (User *)user;

// Override to return a User * instead of a PFUser *
+ (User *)currentUser;

// Refreshed channels
// Should be done after you log in or out
// Or if you leave or join a household
+ (void)refreshChannels;

@end
