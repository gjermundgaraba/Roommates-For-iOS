
#import "Installation.h"
#import <Parse/PFObject+Subclass.h>

@implementation Installation

@dynamic user;
@dynamic household;

- (void)reset {
    [self removeObjectForKey:@"user"];
    [self removeObjectForKey:@"household"];
}

+ (Installation *)currentInstallation {
    return (Installation *)[PFInstallation currentInstallation];
}

+ (NSString *)parseClassName {
    return @"_Installation";
}

@end
