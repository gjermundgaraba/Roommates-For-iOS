//
//  TaskListTableViewController.h
//  Roommates
//
//  Created by Gjermund Bjaanes on 30/03/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "TaskList.h"

@interface TaskListElementsTableViewController : UITableViewController
@property (strong, nonatomic) TaskList *taskList;
@end
