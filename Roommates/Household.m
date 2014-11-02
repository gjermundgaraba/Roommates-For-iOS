
#import "Household.h"
#import <Parse/PFObject+Subclass.h>

@implementation Household

@dynamic householdName;

+ (NSString *)parseClassName {
    return @"Household";
}

@end
