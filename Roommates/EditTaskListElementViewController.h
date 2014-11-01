//
//  EditTaskListElementViewController.h
//  Roommates
//
//  Created by Gjermund Bjaanes on 11/04/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "TaskListElement.h"

@interface EditTaskListElementViewController : UIViewController

// The task list element to be edited
@property (strong, nonatomic) TaskListElement *taskListElement;

@end
