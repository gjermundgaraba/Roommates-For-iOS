
#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "TaskListElement.h"

@interface EditTaskListElementViewController : UIViewController

// The task list element to be edited
@property (strong, nonatomic) TaskListElement *taskListElement;

@end
