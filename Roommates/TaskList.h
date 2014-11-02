
#import <Parse/Parse.h>
#import "Household.h"
#import "User.h"

@interface TaskList : PFObject <PFSubclassing>

@property NSString *listName;
@property Household *household;

@property User *createdBy;
@property BOOL done;

+ (NSString *)parseClassName;

@end
