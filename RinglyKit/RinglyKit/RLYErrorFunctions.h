#import "RLYANCSV1Error.h"
#import "RLYANCSV2Error.h"
#import "RLYActivityTrackingDateError.h"
#import "RLYActivityTrackingUpdateError.h"
#import "RLYDefines.h"
#import "RLYPeripheralError.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - ANCS v1

/**
 *  Returns an error object for the specified ANCS v1 error code.
 *
 *  @param code The error code.
 */
RINGLYKIT_EXTERN NSError *RLYANCSV1Error(RLYANCSV1ErrorCode code);

#pragma mark - ANCS v2

/**
 *  Returns an error object for the specified ANCS v2 error code.
 *
 *  @param code The error code.
 *  @param data The data that caused the error.
 */
RINGLYKIT_EXTERN NSError *RLYANCSV2Error(RLYANCSV2ErrorCode code, NSData *data);

#pragma mark - Activity Tracking Update

/**
 *  Returns an error object for the specified activity tracking update error code.
 *
 *  @param code     The error code.
 *  @param userInfo The error's user info value.
 */
RINGLYKIT_EXTERN NSError *RLYActivityTrackingUpdateError(RLYActivityTrackingUpdateErrorCode code,
                                                         NSDictionary<NSString*, id> *__nullable userInfo);

#pragma mark - Activity Tracking Date

/**
 *  Returns an error object for the specified activity tracking date error code.
 *
 *  @param code     The error code.
 *  @param userInfo The error's user info value.
 */
RINGLYKIT_EXTERN NSError *RLYActivityTrackingDateError(RLYActivityTrackingDateErrorCode code,
                                                       NSDictionary<NSString*, id> *__nullable userInfo);

#pragma mark - Peripheral

/**
 *  Returns an error object for the specified peripheral error code.
 *
 *  @param code The error code.
 */
RINGLYKIT_EXTERN NSError *RLYPeripheralError(RLYPeripheralErrorCode code);

NS_ASSUME_NONNULL_END
