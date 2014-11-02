
#import <Parse/Parse.h>
#import "User.h"
#import "Household.h"

@interface Installation : PFInstallation <PFSubclassing>

@property Household *household;
@property User *user;

- (void)reset;

+ (Installation *)currentInstallation;

+ (NSString *)parseClassName;

@end
