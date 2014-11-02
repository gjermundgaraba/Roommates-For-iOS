
#import "TaskList.h"
#import <Parse/PFObject+Subclass.h>

@implementation TaskList

@dynamic listName;
@dynamic household;

@dynamic createdBy;
@dynamic done;

+ (NSString *)parseClassName {
    return @"TaskList";
}

@end
