//
//  Installation.m
//  Roommates
//
//  Created by Gjermund Bjaanes on 18/04/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import "Installation.h"
#import <Parse/PFObject+Subclass.h>

@implementation Installation

@dynamic user;
@dynamic household;

- (void)reset {
    [self removeObjectForKey:@"user"];
    [self removeObjectForKey:@"household"];
}

+ (Installation *)currentInstallation {
    return (Installation *)[PFInstallation currentInstallation];
}

+ (NSString *)parseClassName {
    return @"_Installation";
}

@end
