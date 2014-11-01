//
//  Invitation.h
//  Roommates
//
//  Created by Gjermund Bjaanes on 16/04/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import <Parse/Parse.h>
#import "User.h"
#import "Household.h"

@interface Invitation : PFObject <PFSubclassing>

@property Household *household;
@property User *invitee;
@property User *inviter;


+ (NSString *)parseClassName;

@end
