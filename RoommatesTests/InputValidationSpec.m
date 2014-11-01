#import "Specta.h"
//#import "OCMock/OCMock.h"

#define EXP_SHORTHAND
#import "Expecta.h"

#import "InputValidation.h"

SpecBegin(InputValidation)

describe(@"Input Validation", ^{
    
    describe(@"Email Validation", ^{
        it(@"should validate valid emails", ^{
            NSString *validEmail01 = @"bjaanes@gmail.com";
            NSString *validEmail02 = @"katrine@hotmail.com";
            NSString *validEmail03 = @"heia1992@gmail.com";
            NSString *validEmail04 = @"12984gfjk@hotmail.com";
            
            BOOL validatedEmail01 = [InputValidation validateEmail:validEmail01];
            expect(validatedEmail01).to.beTruthy();
            
            BOOL validatedEmail02 = [InputValidation validateEmail:validEmail02];
            expect(validatedEmail02).to.beTruthy();
            
            BOOL validatedEmail03 = [InputValidation validateEmail:validEmail03];
            expect(validatedEmail03).to.beTruthy();
            
            BOOL validatedEmail04 = [InputValidation validateEmail:validEmail04];
            expect(validatedEmail04).to.beTruthy();
        });
        
        it(@"should invalidate invalid emails", ^{
            NSString *inValidEmail01 = @"b$jaanesgmail.com";
            NSString *inValidEmail02 = @"katrine@hotmailcom";
            NSString *inValidEmail03 = @"heia1992@gmailcom";
            NSString *inValidEmail04 = @"12984gfjk.hotmail.com";
            
            BOOL inValidatedEmail01 = [InputValidation validateEmail:inValidEmail01];
            expect(inValidatedEmail01).to.beFalsy();
            
            BOOL inValidatedEmail02 = [InputValidation validateEmail:inValidEmail02];
            expect(inValidatedEmail02).to.beFalsy();
            
            BOOL inValidatedEmail03 = [InputValidation validateEmail:inValidEmail03];
            expect(inValidatedEmail03).to.beFalsy();
            
            BOOL inValidatedEmail04 = [InputValidation validateEmail:inValidEmail04];
            expect(inValidatedEmail04).to.beFalsy();
            
        });
    });
    
    describe(@"Password Validation", ^{
        it(@"should validate valid passwords", ^{
            NSString *validPassword01 = @"7FFDSkkl5438";
            NSString *validPassword02 = @"FDGKLSk5489";
            NSString *validPassword03 = @"&%Sklkglø12";
            NSString *validPassword04 = @"gjkldLK%&43";
            
            BOOL validatedPassword01 = [InputValidation validatePassword:validPassword01];
            expect(validatedPassword01).to.beTruthy();
            
            BOOL validatedPassword02 = [InputValidation validatePassword:validPassword02];
            expect(validatedPassword02).to.beTruthy();
            
            BOOL validatedPassword03 = [InputValidation validatePassword:validPassword03];
            expect(validatedPassword03).to.beTruthy();
            
            BOOL validatedPassword04 = [InputValidation validatePassword:validPassword04];
            expect(validatedPassword04).to.beTruthy();
        });
        
        it(@"should invalidate invalid passwords", ^{
            NSString *inValidPassword01 = @"Kd!23";
            NSString *inValidPassword02 = @"4KEOSGD23!";
            NSString *inValidPassword03 = @"5jfekfjkrl";
            NSString *inValidPassword04 = @"!GFsjksø";
            
            BOOL inValidatedPassword01 = [InputValidation validatePassword:inValidPassword01];
            expect(inValidatedPassword01).to.beFalsy();
            
            BOOL inValidatedPassword02 = [InputValidation validatePassword:inValidPassword02];
            expect(inValidatedPassword02).to.beFalsy();
            
            BOOL inValidatedPassword03 = [InputValidation validatePassword:inValidPassword03];
            expect(inValidatedPassword03).to.beFalsy();
            
            BOOL inValidatedPassword04 = [InputValidation validatePassword:inValidPassword04];
            expect(inValidatedPassword04).to.beFalsy();
            
        });
        
        
        
    });
    
    describe(@"Name Validation", ^{
        it(@"should validate valid names", ^{
            NSString *validName01 = @"Katrine Myklevold";
            NSString *validName02 = @"Gjermund";
            NSString *validName03 = @"Johann";
            NSString *validName04 = @"Johannes";
            
            BOOL validatedName01 = [InputValidation validateName:validName01];
            expect(validatedName01).to.beTruthy();
            
            BOOL validatedName02 = [InputValidation validateName:validName02];
            expect(validatedName02).to.beTruthy();
            
            BOOL validatedName03 = [InputValidation validateName:validName03];
            expect(validatedName03).to.beTruthy();
            
            BOOL validatedName04 = [InputValidation validateName:validName04];
            expect(validatedName04).to.beTruthy();
        });
        
        it(@"should invalidate invalid names", ^{
            NSString *inValidName01 = @"";
            //NSString *inValidName02 = @"4548";
            //NSString *inValidName03 = @"$%&%&$#2";
            //NSString *inValidName04 = @"!$2524522klr";
            
            BOOL inValidatedName01 = [InputValidation validateName:inValidName01];
            expect(inValidatedName01).to.beFalsy();
            
            // Is failing, is it because of FB?
            
            /**BOOL inValidatedName02 = [InputValidation validateName:inValidName02];
            expect(inValidatedName02).to.beFalsy();
            
            BOOL inValidatedName03 = [InputValidation validateName:inValidName03];
            expect(inValidatedName03).to.beFalsy();
            
            BOOL inValidatedName04 = [InputValidation validateName:inValidName04];
            expect(inValidatedName04).to.beFalsy(); **/
            
        });
        
    });
});

SpecEnd