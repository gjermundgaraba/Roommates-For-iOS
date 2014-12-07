
#import "ErrorHandler.h"
#import <Parse/Parse.h>

@implementation ErrorHandler

+ (void)handleError:(NSError *)error {
    NSInteger errorCode = error.code;
    
    NSString *errorMessage;
    if (errorCode == kPFErrorAccountAlreadyLinked) {
        errorMessage = NSLocalizedString(@"208: An existing account already linked to another user.", nil);
    } else if (errorCode == kPFErrorCacheMiss) {
        errorMessage = NSLocalizedString(@"120: The results were not found in the cache.", nil);
    } else if (errorCode == kPFErrorCommandUnavailable) {
        errorMessage = NSLocalizedString(@"108: Tried to access a feature only available internally.", nil);
    } else if (errorCode == kPFErrorConnectionFailed) {
        errorMessage = NSLocalizedString(@"100: The connection to the Parse servers failed.", nil);
    } else if (errorCode == kPFErrorDuplicateValue) {
        errorMessage = NSLocalizedString(@"137: A unique field was given a value that is already taken.", nil);
    } else if (errorCode == kPFErrorExceededQuota) {
        errorMessage = NSLocalizedString(@"140: Exceeded an application quota. Upgrade to resolve.", nil);
    } else if (errorCode == kPFErrorFacebookAccountAlreadyLinked) {
        errorMessage = NSLocalizedString(@"208: An existing Facebook account already linked to another user.", nil);
    } else if (errorCode == kPFErrorFacebookIdMissing) {
        errorMessage = NSLocalizedString(@"250: Facebook id missing from request", nil);
    } else if (errorCode == kPFErrorFacebookInvalidSession) {
        errorMessage = NSLocalizedString(@"251: Invalid Facebook session", nil);
    } else if (errorCode == kPFErrorFileDeleteFailure) {
        errorMessage = NSLocalizedString(@"153: Fail to delete file.", nil);
    } else if (errorCode == kPFErrorIncorrectType) {
        errorMessage = NSLocalizedString(@"111: Field set to incorrect type.", nil);
    } else if (errorCode == kPFErrorInternalServer) {
        errorMessage = NSLocalizedString(@"1: Internal server error. No information available.", nil);
    } else if (errorCode == kPFErrorInvalidACL) {
        errorMessage = NSLocalizedString(@"123: Invalid ACL. An ACL with an invalid format was saved. This should not happen if you use PFACL.", nil);
    } else if (errorCode == kPFErrorInvalidChannelName) {
        errorMessage = NSLocalizedString(@"112: Invalid channel name. A channel name is either an empty string (the broadcast channel) or contains only a-zA-Z0-9_ characters and starts with a letter.", nil);
    } else if (errorCode == kPFErrorInvalidClassName) {
        errorMessage = NSLocalizedString(@"103: Missing or invalid classname. Classnames are case-sensitive. They must start with a letter, and a-zA-Z0-9_ are the only valid characters.", nil);
    } else if (errorCode == kPFErrorInvalidDeviceToken) {
        errorMessage = NSLocalizedString(@"114: Invalid device token.", nil);
    } else if (errorCode == kPFErrorInvalidEmailAddress) {
        errorMessage = NSLocalizedString(@"125: The email address was invalid.", nil);
    } else if (errorCode == kPFErrorInvalidEventName) {
        errorMessage = NSLocalizedString(@"160: Invalid event name.", nil);
    } else if (errorCode == kPFErrorInvalidFileName) {
        errorMessage = NSLocalizedString(@"122: Invalid file name. A file name contains only a-zA-Z0-9_. characters and is between 1 and 36 characters.", nil);
    } else if (errorCode == kPFErrorInvalidImageData) {
        errorMessage = NSLocalizedString(@"150: Fail to convert data to image.", nil);
    } else if (errorCode == kPFErrorInvalidJSON) {
        errorMessage = NSLocalizedString(@"107: Malformed json object. A json dictionary is expected.", nil);
    } else if (errorCode == kPFErrorInvalidKeyName) {
        errorMessage = NSLocalizedString(@"105: Invalid key name. Keys are case-sensitive. They must start with a letter, and a-zA-Z0-9_ are the only valid characters.", nil);
    } else if (errorCode == kPFErrorInvalidLinkedSession) {
        errorMessage = NSLocalizedString(@"251: Invalid linked session.", nil);
    } else if (errorCode == kPFErrorInvalidNestedKey) {
        errorMessage = NSLocalizedString(@"121: Keys in NSDictionary values may not include '$' or '.'.", nil);
    } else if (errorCode == kPFErrorInvalidPointer) {
        errorMessage = NSLocalizedString(@"106: Malformed pointer. Pointers must be arrays of a classname and an object id.", nil);
    } else if (errorCode == kPFErrorInvalidProductIdentifier) {
        errorMessage = NSLocalizedString(@"146: The product identifier is invalid", nil);
    } else if (errorCode == kPFErrorInvalidPurchaseReceipt) {
        errorMessage = NSLocalizedString(@"144: Product purchase receipt is invalid", nil);
    } else if (errorCode == kPFErrorInvalidQuery) {
        errorMessage = NSLocalizedString(@"102: You tried to find values matching a datatype that doesn't support exact database matching, like an array or a dictionary.", nil);
    } else if (errorCode == kPFErrorInvalidRoleName) {
        errorMessage = NSLocalizedString(@"139: Role's name is invalid.", nil);
    } else if (errorCode == kPFErrorInvalidServerResponse) {
        errorMessage = NSLocalizedString(@"148: The Apple server response is not valid", nil);
    } else if (errorCode == kPFErrorLinkedIdMissing) {
        errorMessage = NSLocalizedString(@"250: Linked id missing from request", nil);
    } else if (errorCode == kPFErrorMissingObjectId) {
        errorMessage = NSLocalizedString(@"104: Missing object id.", nil);
    } else if (errorCode == kPFErrorObjectNotFound) {
        errorMessage = NSLocalizedString(@"101: Object doesn't exist, or has an incorrect password.", nil);
    } else if (errorCode == kPFErrorObjectTooLarge) {
        errorMessage = NSLocalizedString(@"116: The object is too large.", nil);
    } else if (errorCode == kPFErrorOperationForbidden) {
        errorMessage = NSLocalizedString(@"119: That operation isn't allowed for clients.", nil);
    } else if (errorCode == kPFErrorPaymentDisabled) {
        errorMessage = NSLocalizedString(@"145: Payment is disabled on this device", nil);
    } else if (errorCode == kPFErrorProductDownloadFileSystemFailure) {
        errorMessage = NSLocalizedString(@"149: Product fails to download due to file system error", nil);
    } else if (errorCode == kPFErrorProductNotFoundInAppStore) {
        errorMessage = NSLocalizedString(@"147: The product is not found in the App Store", nil);
    } else if (errorCode == kPFErrorPushMisconfigured) {
        errorMessage = NSLocalizedString(@"115: Push is misconfigured. See details to find out how.", nil);
    } else if (errorCode == kPFErrorReceiptMissing) {
        errorMessage = NSLocalizedString(@"143: Product purchase receipt is missing", nil);
    } else if (errorCode == kPFErrorTimeout) {
        errorMessage = NSLocalizedString(@"124: The request timed out on the server. Typically this indicates the request is too expensive.", nil);
    }
}






/*



kPFErrorUnsavedFile

151: Unsaved file.
kPFErrorUserCannotBeAlteredWithoutSession

206: The user cannot be altered by a client without the session.
kPFErrorUserCanOnlyBeCreatedThroughSignUp

207: Users can only be created through sign up
kPFErrorUserEmailMissing

204: The email is missing, and must be specified
kPFErrorUserEmailTaken

203: Email has already been taken
kPFErrorUserIdMismatch

209: User ID mismatch
kPFErrorUsernameMissing

200: Username is missing or empty
kPFErrorUsernameTaken

202: Username has already been taken
kPFErrorUserPasswordMissing

201: Password is missing or empty
kPFErrorUserWithEmailNotFound

205: A user with the specified email was not found
kPFScriptError

141: Cloud Code script had an error.
kPFValidationError

142: Cloud Code validation failed.
*/

@end
