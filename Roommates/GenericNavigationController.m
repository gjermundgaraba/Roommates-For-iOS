//
//  GenericNavigationController.m
//  Roommates
//
//  Created by Gjermund Bjaanes on 30/03/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//
//  Generic Navigation Controller
//  Only for setting the navigationbar colors and such

#import "GenericNavigationController.h"

@interface GenericNavigationController ()

@end

@implementation GenericNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationBar.backgroundColor = [UIColor whiteColor];
    self.navigationBar.translucent = NO;
}

@end
