
#import <Parse/Parse.h>

@interface Household : PFObject <PFSubclassing>

@property NSString *householdName;

+ (NSString *)parseClassName;

@end
