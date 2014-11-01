//
//  Event.m
//  Roommates
//
//  Created by Gjermund Bjaanes on 16/04/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import "Event.h"
#import <Parse/PFObject+Subclass.h>
#import "TaskList.h"
#import "Expense.h"

@implementation Event

@dynamic household;
@dynamic type;
@dynamic user;
@dynamic objects;

- (NSString *)descriptionString {
    int type = self.type.intValue;
    NSString *descriptionString;
    
    switch (type) {
        case 0: // Join
            descriptionString = [NSString stringWithFormat:@"%@ joined %@", self.user.displayName, self.household.householdName];
            break;
        case 1: // Leave
            descriptionString = [NSString stringWithFormat:@"%@ left %@", self.user.displayName, self.household.householdName];
            break;
        case 2: { // Add tasklist
            TaskList *taskList = (TaskList *)self.objects[0];
            if ([taskList isEqual:[NSNull null]]) return @"<Task List Deleted>";
            descriptionString = [NSString stringWithFormat:@"%@ created a new task list: %@", self.user.displayName, taskList.listName];
            break;
        }
        case 3: {// Finished Tasklist
            TaskList *taskList = (TaskList *)self.objects[0];
            if ([taskList isEqual:[NSNull null]]) return @"<Task List Deleted>";
            descriptionString = [NSString stringWithFormat:@"%@ finished a task list: %@", self.user.displayName, taskList.listName];
            break;
        }
        case 4: { // Add expense
            Expense *expense = (Expense *)self.objects[0];
            if ([expense isEqual:[NSNull null]]) return @"<Expense Deleted>";
            descriptionString = [NSString stringWithFormat:@"%@ created a new expense: %@", self.user.displayName, expense.name];
            break;
        }
        case 5: { // Settled Expense
            Expense *expense = (Expense *)self.objects[0];
            if ([expense isEqual:[NSNull null]]) return @"<Expense Deleted>";
            descriptionString = [NSString stringWithFormat:@"%@ settled an expense: %@", self.user.displayName, expense.name];
            break;
        }
        default:
            break;
    }
    
    return descriptionString;
}

+ (NSString *)parseClassName {
    return @"Event";
}

@end
