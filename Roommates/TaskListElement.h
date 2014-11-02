
#import <Parse/Parse.h>
#import "TaskList.h"
#import "User.h"


@interface TaskListElement : PFObject <PFSubclassing>

@property NSString *elementName;
@property TaskList *taskList;

@property User *finishedBy;
@property User *createdBy;

+ (NSString *)parseClassName;

@end
