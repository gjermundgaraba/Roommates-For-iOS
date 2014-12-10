//
//  NoteUITableViewCell.h
//  Roommates
//
//  Created by Gjermund Bjaanes on 09/12/14.
//  Copyright (c) 2014 Gjermund Bjaanes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@interface NoteUITableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet PFImageView *profilePicture;
@property (weak, nonatomic) IBOutlet UILabel *displayName;
@property (weak, nonatomic) IBOutlet UILabel *noteBody;


@end
