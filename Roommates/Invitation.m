//
//  Invitation.m
//  Roommates
//
//  Created by Gjermund Bjaanes on 16/04/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import "Invitation.h"
#import <Parse/PFObject+Subclass.h>

@implementation Invitation

@dynamic household;
@dynamic invitee;
@dynamic inviter;

+ (NSString *)parseClassName {
    return @"Invitation";
}

@end
