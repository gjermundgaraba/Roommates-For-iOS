
#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@interface NoteTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet PFImageView *profilePicture;
@property (weak, nonatomic) IBOutlet UILabel *displayName;
@property (weak, nonatomic) IBOutlet UILabel *noteBody;

@end
