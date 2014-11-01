//
//  TaskList.h
//  Roommates
//
//  Created by Gjermund Bjaanes on 16/04/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import <Parse/Parse.h>
#import "Household.h"
#import "User.h"

@interface TaskList : PFObject <PFSubclassing>

@property NSString *listName;
@property Household *household;

@property User *createdBy;
@property BOOL done;

+ (NSString *)parseClassName;

@end
