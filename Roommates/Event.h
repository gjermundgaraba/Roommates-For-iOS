
#import <Parse/Parse.h>
#import "Household.h"
#import "User.h"

@interface Event : PFObject <PFSubclassing>

@property Household *household;
@property NSNumber *type;
@property User *user;
@property NSArray *objects;

- (NSString *)descriptionString;
- (NSString *)descriptionTitle;

+ (NSString *)parseClassName;

@end
