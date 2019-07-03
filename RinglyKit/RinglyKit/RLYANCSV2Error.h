#import <Foundation/Foundation.h>
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  The error domain for ANCS version 2 errors.
 */
RINGLYKIT_EXTERN NSString *const RLYANCSV2ErrorDomain;

/**
 *  Enumerates ANCS version 2 error codes, which will have the domain `RLYANCSV2ErrorDomain`.
 */
typedef NS_ENUM(NSInteger, RLYANCSV2ErrorCode)
{
    /**
     *  The data size was incorrect for its contents.
     */
    RLYANCSV2ErrorCodeIncorrectDataSize,
    
    /**
     *  The notification attributes command identifier was invalid.
     */
    RLYANCSV2ErrorCodeInvalidNotificationAttributesCommandIdentifier,
    
    /**
     *  The application attributes command identifier was invalid.
     */
    RLYANCSV2ErrorCodeInvalidApplicationAttributesCommandIdentifier,
    
    /**
     *  The notification did not include a title attribute.
     */
    RLYANCSV2ErrorCodeMissingTitle,
    
    /**
     *  The notification did not include a date attribute.
     */
    RLYANCSV2ErrorCodeMissingDate
};


RINGLYKIT_EXTERN NSString *const RLYANCSV2DataErrorKey;

NS_ASSUME_NONNULL_END
