
#import <Parse/Parse.h>
#import "Household.h"
#import "User.h"

@interface Expense : PFObject <PFSubclassing>

@property NSString *name;
@property Household *household;
@property User *owed;
@property NSArray *notPaidUp; // of User *
@property NSArray *paidUp; // of User *
@property NSNumber *totalAmount;
@property BOOL isSettled;
@property NSString *details;

+ (NSString *)parseClassName;

@end
