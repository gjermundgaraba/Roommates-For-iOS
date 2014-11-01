//
//  TaskListElement.m
//  Roommates
//
//  Created by Gjermund Bjaanes on 16/04/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import "TaskListElement.h"
#import <Parse/PFObject+Subclass.h>

@implementation TaskListElement

@dynamic elementName;
@dynamic taskList;
@dynamic finishedBy;
@dynamic createdBy;

+ (NSString *)parseClassName {
    return @"TaskListElement";
}

@end
