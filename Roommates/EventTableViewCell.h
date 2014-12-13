
#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@interface EventTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet PFImageView *profilePicture;
@property (weak, nonatomic) IBOutlet UILabel *eventTitle;
@property (weak, nonatomic) IBOutlet UILabel *eventText;
@property (weak, nonatomic) IBOutlet UILabel *time;

@end
