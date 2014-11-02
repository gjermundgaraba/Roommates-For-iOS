
#import "Invitation.h"
#import <Parse/PFObject+Subclass.h>

@implementation Invitation

@dynamic household;
@dynamic invitee;
@dynamic inviter;

+ (NSString *)parseClassName {
    return @"Invitation";
}

@end
