//
//  UserData.h
//  Roommates
//
//  Created by Gjermund Bjaanes on 15/03/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//
//  Class for validation user data.

#import <Foundation/Foundation.h>

@interface InputValidation : NSObject

/*
 *  Validates a name (first or last)
 *  A name needs to be ?
 *  to be validated
 */
+ (BOOL)validateName:(NSString *)lastname;

/*
 *  Validates a password
 *  A password needs to be alpha, numeric, lower, upper ???
 *  to be validated
 *  Regex used: ((?=.*\\d)(?=.*[a-z])(?=.*[A-Z]).{6,20})
 */
+ (BOOL)validatePassword:(NSString *)password;

/*
 *  Validates email address
 *  Regex used: [A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}
 */
+ (BOOL)validateEmail:(NSString *)email;

+ (BOOL)validateTotalAmount:(NSString *)totalAmount;
@end
