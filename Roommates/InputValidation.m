//
//  UserData.m
//  Roommates
//
//  Created by Gjermund Bjaanes on 15/03/14.
//  Copyright (c) 2014 Real Kode. All rights reserved.
//

#import "InputValidation.h"

@implementation InputValidation


+ (BOOL)validateName:(NSString *) names {
    if ([names isEqualToString:@""]) {
        return NO;
    }
    else {
        return YES;
    }
    /*NSString *nameRegex = @"[a-zA-Z ]+";
    NSPredicate *nameTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", nameRegex];
    return [nameTest evaluateWithObject:names];*/
}


+ (BOOL)validatePassword:(NSString *)password {
    NSString *passwordRegex = @"((?=.*\\d)(?=.*[a-z])(?=.*[A-Z]).{6,20})";
    NSPredicate *passwordTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", passwordRegex];
    return [passwordTest evaluateWithObject:password];
}


+ (BOOL)validateEmail:(NSString *)email {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:email];
}


+ (BOOL)isFirstCharacterALetter:(NSString *)str {
    NSRange first = [str rangeOfComposedCharacterSequenceAtIndex:0];
    NSRange match = [str rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet] options:0 range:first];
    if (match.location != NSNotFound) {
        return YES;
    }
    else {
        return NO;
    }
}


+ (BOOL)isAlphaNumeric:(NSString *)str
{
    //Inverts NSCharacterSet to find all unwanted characters, then compare str
    NSCharacterSet *unwantedCharacters = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    return ([str rangeOfCharacterFromSet:unwantedCharacters].location == NSNotFound) ? YES : NO;
}

+ (BOOL)validateTotalAmount:(NSString *)totalAmount {
    if ([totalAmount isEqualToString:@""]) return NO;
    
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber * myNumber = [f numberFromString:totalAmount];
    
    if (!myNumber) return NO;
    
    if (myNumber.doubleValue <= 0.0) return NO;
    
    return YES;
}


@end
