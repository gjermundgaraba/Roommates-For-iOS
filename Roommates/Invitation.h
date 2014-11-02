
#import <Parse/Parse.h>
#import "User.h"
#import "Household.h"

@interface Invitation : PFObject <PFSubclassing>

@property Household *household;
@property User *invitee;
@property User *inviter;


+ (NSString *)parseClassName;

@end
