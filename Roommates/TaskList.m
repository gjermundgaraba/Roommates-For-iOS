//
//  TaskList.m
//  Roommates
//
//  Created by Gjermund Bjaanes on 16/04/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import "TaskList.h"
#import <Parse/PFObject+Subclass.h>

@implementation TaskList

@dynamic listName;
@dynamic household;

@dynamic createdBy;
@dynamic done;

+ (NSString *)parseClassName {
    return @"TaskList";
}

@end
