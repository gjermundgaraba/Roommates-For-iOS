//
//  Household.h
//  Roommates
//
//  Created by Gjermund Bjaanes on 16/04/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import <Parse/Parse.h>

@interface Household : PFObject <PFSubclassing>

@property NSString *householdName;

+ (NSString *)parseClassName;

@end
