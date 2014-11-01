//
//  Household.m
//  Roommates
//
//  Created by Gjermund Bjaanes on 16/04/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import "Household.h"
#import <Parse/PFObject+Subclass.h>

@implementation Household

@dynamic householdName;

+ (NSString *)parseClassName {
    return @"Household";
}

@end
