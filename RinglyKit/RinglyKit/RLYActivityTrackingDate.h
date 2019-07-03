#import <Foundation/Foundation.h>
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Intervals

/**
 *  Activity tracking dates are stored on the peripheral as 23-bit unsigned integers. We represent them as the next
 *  largest type. However, `RLYActivityTrackingDate` will not allow an invalid date to be initialized, and will return
 *  an error instead.
 *
 *  Activity tracking data is tracked per-minute, not per-second, so `1` is one minute after
 *  `RLYActivityTrackingDateReferenceTimestamp`.
 */
typedef uint32_t RLYActivityTrackingMinute;

/**
 *  The minimum supported interval value - `0`.
 */
RINGLYKIT_EXTERN RLYActivityTrackingMinute const RLYActivityTrackingMinuteMin;

/**
 *  The maximum supported interval value - `8388607`.
 */
RINGLYKIT_EXTERN RLYActivityTrackingMinute const RLYActivityTrackingMinuteMax;

/**
 *  Converts an activity tracking date to a Unix timestamp.
 *
 *  @param interval The activity tracking date interval.
 */
RINGLYKIT_EXTERN time_t RLYActivityTrackingMinuteToTimestamp(RLYActivityTrackingMinute interval);

/**
 *  Converts an activity tracking date to a Foundation `NSDate`.
 *
 *  @param interval The activity tracking date interval.
 */
RINGLYKIT_EXTERN NSDate *RLYActivityTrackingMinuteToNSDate(RLYActivityTrackingMinute interval);

/**
 *  A three-byte representation of a `RLYActivityTrackingMinute`.
 */
typedef struct
{
    /**
     *  The first byte.
     */
    uint8_t first;

    /**
     *  The second byte.
     */
    uint8_t second;

    /**
     *  The third byte.
     */
    uint8_t third;
} RLYActivityTrackingMinuteBytes;

/**
 *  Constructs a `RLYActivityTrackingMinuteBytes` structure.
 *
 *  @param first  The first byte.
 *  @param second The second byte.
 *  @param third  The third byte.
 */
RINGLYKIT_EXTERN RLYActivityTrackingMinuteBytes
    RLYActivityTrackingMinuteBytesMake(uint8_t first, uint8_t second, uint8_t third);

/**
 *  Returns the bytes for the interval.
 *
 *  @param interval The interval.
 */
RINGLYKIT_EXTERN RLYActivityTrackingMinuteBytes
    RLYActivityTrackingMinuteBytesFromMinute(RLYActivityTrackingMinute interval);

/**
 *  Returns the interval for the bytes.
 *
 *  @param bytes The bytes.
 */
RINGLYKIT_EXTERN RLYActivityTrackingMinute
    RLYActivityTrackingMinuteBytesToMinute(RLYActivityTrackingMinuteBytes bytes);

#pragma mark - Timestamps

/**
 *  The reference timestamp (equivalent to `0`) for `RLYActivityTrackingMinute`.
 */
RINGLYKIT_EXTERN time_t const RLYActivityTrackingDateReferenceTimestamp;

#pragma mark - Date Object

/**
 *  An activity tracking date.
 */
RINGLYKIT_FINAL @interface RLYActivityTrackingDate : NSObject

#pragma mark - Initialization

/**
 *  `+new` is unavailable, use a class constructor instead.
 */
+(instancetype)new NS_UNAVAILABLE;

/**
 *  `-init` is unavailable, use a class constructor instead.
 */
-(instancetype)init NS_UNAVAILABLE;

/**
 *  Creates an activity tracking date from a `RLYActivityTrackingMinute` value, if possible.
 *
 *  @param minute The minute value.
 *  @param error  An error pointer.
 */
+(nullable instancetype)dateWithMinute:(RLYActivityTrackingMinute)minute error:(NSError**)error;

/**
 *  Creates an activity tracking date from a Unix timestamp, if possible.
 *
 *  Dates are associated with a 23-bit minute-based timestamp. Any seconds component will be removed dropped from the
 *  date returned from this message. Therefore, the value of the `timestamp` property, in most cases, will not be equal
 *  to the input timestamp.
 *
 *  @param timestamp The Unix timestamp value.
 *  @param error     An error pointer.
 */
+(nullable instancetype)dateWithTimestamp:(time_t)timestamp error:(NSError**)error;

/**
 *  Creates an activity tracking date from an `NSDate` object, if possible.
 *
 *  Dates are associated with a 23-bit minute-based timestamp. Any seconds component will be removed dropped from the
 *  date returned from this message. Therefore, the value of the `date` property, in most cases, will not be equal to
 *  the input date.
 *
 *  @param date  The date object.
 *  @param error An error pointer.
 */
+(nullable instancetype)dateWithDate:(NSDate*)date error:(NSError**)error;

#pragma mark - Boundary Dates

/**
 *  The earliest possible date, with an interval equal to `RLYActivityTrackingMinuteMin`.
 */
+(instancetype)minimumDate;

/**
 *  The latest possible date, with an interval equal to `RLYActivityTrackingMinuteMax`.
 */
+(instancetype)maximumDate;

#pragma mark - Representations

/**
 *  A representation of the receiver as a `RLYActivityTrackingMinute` value.
 */
@property (nonatomic, readonly) RLYActivityTrackingMinute minute;

/**
 *  A representation of the receiver as a Unix timestamp.
 */
@property (nonatomic, readonly) time_t timestamp;

/**
 *  A representation of the receiver as an `NSDate` object.
 */
@property (nonatomic, readonly) NSDate *date;

@end

NS_ASSUME_NONNULL_END
