//
//  TaskListElement.h
//  Roommates
//
//  Created by Gjermund Bjaanes on 16/04/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import <Parse/Parse.h>
#import "TaskList.h"
#import "User.h"


@interface TaskListElement : PFObject <PFSubclassing>

@property NSString *elementName;
@property TaskList *taskList;

@property User *finishedBy;
@property User *createdBy;

+ (NSString *)parseClassName;

@end
