#import <Foundation/Foundation.h>
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  The error domain for ANCS version 1 errors.
 */
RINGLYKIT_EXTERN NSString *const RLYANCSV1ErrorDomain;

/**
 *  Enumerates ANCS version 1 error codes, which will have the domain `RLYANCSV1ErrorDomain`.
 */
typedef NS_ENUM(NSInteger, RLYANCSV1ErrorCode)
{
    /**
     *  A notification was being parsed, but a new part was appended with a different header identifier.
     */
    RLYANCSV1ErrorCodeDifferentHeader,
    
    /**
     *  A data packet did not include a header.
     */
    RLYANCSV1ErrorCodeInvalidHeader
};

NS_ASSUME_NONNULL_END
