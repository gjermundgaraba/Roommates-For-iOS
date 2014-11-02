
#import <Parse/Parse.h>
#import "User.h"
#import "Household.h"

@interface Note : PFObject <PFSubclassing>

@property NSString *body;
@property Household *household;
@property User *createdBy;


+ (NSString *)parseClassName;

@end
