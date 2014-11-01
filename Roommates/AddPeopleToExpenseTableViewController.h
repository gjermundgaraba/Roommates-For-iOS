//
//  AddPeopleToExpenseTableViewController.h
//  Roommates
//
//  Created by Gjermund Bjaanes on 27/04/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Expense.h"

@interface AddPeopleToExpenseTableViewController : UITableViewController
@property (strong, nonatomic) Expense *expense; // The expense we are editing people on
@end
