//
//  Event.h
//  Roommates
//
//  Created by Gjermund Bjaanes on 16/04/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import <Parse/Parse.h>
#import "Household.h"
#import "User.h"

@interface Event : PFObject <PFSubclassing>

@property Household *household;
@property NSNumber *type;
@property User *user;
@property NSArray *objects;

- (NSString *)descriptionString;

+ (NSString *)parseClassName;

@end
