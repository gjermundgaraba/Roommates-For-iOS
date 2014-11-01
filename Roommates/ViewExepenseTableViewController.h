//
//  ViewExepenseTableViewController.h
//  Roommates
//
//  Created by Gjermund Bjaanes on 26/04/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Expense.h"

@interface ViewExepenseTableViewController : UITableViewController
@property (strong, nonatomic) Expense *expense; // The expense we are viewing
@end
