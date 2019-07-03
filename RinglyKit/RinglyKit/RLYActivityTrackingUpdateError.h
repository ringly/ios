#import <Foundation/Foundation.h>
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Activity Tracking Data Errors
RINGLYKIT_EXTERN NSString *const RLYActivityTrackingUpdateErrorDomain;

typedef NS_ENUM(NSInteger, RLYActivityTrackingUpdateErrorCode)
{
    /**
     *  The data provided to parse was of an incorrect length (not `% 5 == 0`).
     */
    RLYActivityTrackingUpdateErrorCodeIncorrectDataLength,

    /**
     *  A date error occurred. Check the value of `NSUnderlyingErrorKey` for more information.
     */
    RLYActivityTrackingUpdateErrorCodeDateError
};

/**
 *  A user info key containing the activity tracking data that caused the error.
 */
RINGLYKIT_EXTERN NSString *const RLYActivityTrackingUpdateInvalidDataErrorKey;

NS_ASSUME_NONNULL_END
