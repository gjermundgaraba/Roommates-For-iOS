//
//  Note.h
//  Roommates
//
//  Created by Gjermund Bjaanes on 16/04/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import <Parse/Parse.h>
#import "User.h"
#import "Household.h"

@interface Note : PFObject <PFSubclassing>

@property NSString *body;
@property Household *household;
@property User *createdBy;


+ (NSString *)parseClassName;

@end
