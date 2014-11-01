//
//  Installation.h
//  Roommates
//
//  Created by Gjermund Bjaanes on 18/04/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import <Parse/Parse.h>
#import "User.h"
#import "Household.h"

@interface Installation : PFInstallation <PFSubclassing>

@property Household *household;
@property User *user;

- (void)reset;

+ (Installation *)currentInstallation;

+ (NSString *)parseClassName;

@end
