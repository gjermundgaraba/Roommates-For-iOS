
#import <Parse/Parse.h>
#import "Household.h"

@interface User : PFUser <PFSubclassing>

@property Household *activeHousehold;
@property NSString *displayName;
@property PFFile *profilePicture;

@property (readonly) NSString *userChannel;
@property (readonly) NSString *householdChannel;

- (BOOL)isMemberOfAHousehold;

+ (NSString *)parseClassName;

+ (void)logInWithUsernameInBackground:(NSString *)username password:(NSString *)password block:(void (^)(User *user, NSError *error))block;

+ (User *)user;

+ (User *)currentUser;

+ (BOOL)isAnyoneLoggedIn;

// Should be done after you log in or out, or if you leave or join a household
+ (void)refreshChannels;

@end
