
#import "Note.h"
#import <Parse/PFObject+Subclass.h>

@implementation Note

@dynamic body;
@dynamic household;
@dynamic createdBy;

+ (NSString *)parseClassName {
    return @"Note";
}

@end
