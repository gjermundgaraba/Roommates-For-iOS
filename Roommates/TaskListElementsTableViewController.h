
#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "TaskList.h"

@interface TaskListElementsTableViewController : UITableViewController
@property (strong, nonatomic) TaskList *taskList;
@end
