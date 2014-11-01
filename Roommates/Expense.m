//
//  Expense.m
//  Roommates
//
//  Created by Gjermund Bjaanes on 25/04/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import "Expense.h"
#import <Parse/PFObject+Subclass.h>

@implementation Expense

@dynamic name;
@dynamic household;
@dynamic owed;
@dynamic notPaidUp; // of User *
@dynamic paidUp; // of User *
@dynamic totalAmount;
@dynamic isSettled;
@dynamic details;

+ (NSString *)parseClassName {
    return @"Expense";
}

@end
