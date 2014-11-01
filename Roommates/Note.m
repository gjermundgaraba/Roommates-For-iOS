//
//  Note.m
//  Roommates
//
//  Created by Gjermund Bjaanes on 16/04/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import "Note.h"
#import <Parse/PFObject+Subclass.h>

@implementation Note

@dynamic body;
@dynamic household;
@dynamic createdBy;

+ (NSString *)parseClassName {
    return @"Note";
}

@end
