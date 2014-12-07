
#import "Event.h"
#import <Parse/PFObject+Subclass.h>
#import "TaskList.h"
#import "Expense.h"

@implementation Event

@dynamic household;
@dynamic type;
@dynamic user;
@dynamic objects;

- (NSString *)descriptionString {
    int type = self.type.intValue;
    NSString *descriptionString;
    
    switch (type) {
        case 0: // Join
            descriptionString = [NSString stringWithFormat:NSLocalizedString(@"%@ joined %@", nil), self.user.displayName, self.household.householdName];
            break;
        case 1: // Leave
            descriptionString = [NSString stringWithFormat:NSLocalizedString(@"%@ left %@", nil), self.user.displayName, self.household.householdName];
            break;
        case 2: { // Add tasklist
            TaskList *taskList = (TaskList *)self.objects[0];
            if ([taskList isEqual:[NSNull null]]) return @"<Task List Deleted>";
            descriptionString = [NSString stringWithFormat:NSLocalizedString(@"%@ created a new task list: %@", nil), self.user.displayName, taskList.listName];
            break;
        }
        case 3: {// Finished Tasklist
            TaskList *taskList = (TaskList *)self.objects[0];
            if ([taskList isEqual:[NSNull null]]) return @"<Task List Deleted>";
            descriptionString = [NSString stringWithFormat:NSLocalizedString(@"%@ finished a task list: %@", nil), self.user.displayName, taskList.listName];
            break;
        }
        case 4: { // Add expense
            Expense *expense = (Expense *)self.objects[0];
            if ([expense isEqual:[NSNull null]]) return @"<Expense Deleted>";
            descriptionString = [NSString stringWithFormat:NSLocalizedString(@"%@ created a new expense: %@", nil), self.user.displayName, expense.name];
            break;
        }
        case 5: { // Settled Expense
            Expense *expense = (Expense *)self.objects[0];
            if ([expense isEqual:[NSNull null]]) return @"<Expense Deleted>";
            descriptionString = [NSString stringWithFormat:NSLocalizedString(@"%@ settled an expense: %@", nil), self.user.displayName, expense.name];
            break;
        }
        default:
            break;
    }
    
    return descriptionString;
}

+ (NSString *)parseClassName {
    return @"Event";
}

@end
