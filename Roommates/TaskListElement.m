
#import "TaskListElement.h"
#import <Parse/PFObject+Subclass.h>

@implementation TaskListElement

@dynamic elementName;
@dynamic taskList;
@dynamic finishedBy;
@dynamic createdBy;

+ (NSString *)parseClassName {
    return @"TaskListElement";
}

@end
