#import "RLYActivityTrackingDate.h"
#import "RLYPeripheralEnumerations.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  The options for activity tracking accelerometer sensitivity.
 */
typedef NS_ENUM(uint8_t, RLYActivityTrackingSensitivity)
{
    /**
     *  2G.
     */
    RLYActivityTrackingSensitivity2G = 0,

    /**
     *  4G.
     */
    RLYActivityTrackingSensitivity4G = 1,

    /**
     *  8G.
     */
    RLYActivityTrackingSensitivity8G = 2,

    /**
     *  16G.
     */
    RLYActivityTrackingSensitivity16G = 3
};

/**
 *  The options for activity tracking modes.
 */
typedef NS_ENUM(uint8_t, RLYActivityTrackingMode)
{
    /**
     *  A mode that uses less power at the expense of resolution.
     */
    RLYActivityTrackingModeLowPower,

    /**
     *  A mode with a balance of power and resolution.
     */
    RLYActivityTrackingModeNormal,

    /**
     *  A mode that provides higher-resolution data at the expense of power usage.
     */
    RLYActivityTrackingModeHighResolution
};

typedef uint16_t RLYActivityTrackingPeakIntensity;
typedef uint16_t RLYActivityTrackingPeakHeight;

@protocol RLYPeripheralActivityTracking <NSObject>

#pragma mark - Support

/**
 *  Whether or not the activity tracking feature is supported.
 */
@property (nonatomic, readonly) RLYPeripheralFeatureSupport activityTrackingSupport;

/**
 *  Whether or not the receiver is subscribed to notifications for activity tracking data.
 *
 *  This value should be `YES` before attempting to read activity data, to ensure that all data is read correctly.
 */
@property (nonatomic, readonly, getter=isSubscribedToActivityNotifications) BOOL subscribedToActivityNotifications;

#pragma mark - Reading Activity Tracking Data

/**
 *  Instructs the peripheral to read activity tracking data since the specified date.
 *
 *  @param date  Activity data will be requested for dates after, but not including, this date.
 *  @param error An error pointer.
 */
-(BOOL)readActivityTrackingDataSinceDate:(RLYActivityTrackingDate*)date error:(NSError**)error
    NS_SWIFT_NAME(readActivityTrackingDataSince(date:));

#pragma mark - Starting and Stopping Activity Tracking

/**
 *  Instructs the peripheral to start or stop activity tracking.
 *
 *  @param enabled              Whether or not activity tracking should be enabled.
 *  @param sensitivity          The accelerometer sensitivity.
 *  @param mode                 The accelerometer mode.
 *  @param minimumPeakIntensity The minimum peak power of the FFT necessary to trigger step counting in the time window.
 *  @param minimumPeakHeight    The minimum height necessary for a peak to be counted as a step, if the time window has
 *                              already been identified as containing steps.
 *  @param error                An error pointer.
 */
-(BOOL)updateActivityTrackingWithEnabled:(BOOL)enabled
                             sensitivity:(RLYActivityTrackingSensitivity)sensitivity
                                    mode:(RLYActivityTrackingMode)mode
                    minimumPeakIntensity:(RLYActivityTrackingPeakIntensity)minimumPeakIntensity
                       minimumPeakHeight:(RLYActivityTrackingPeakHeight)minimumPeakHeight
                                   error:(NSError**)error
    NS_SWIFT_NAME(updateActivityTrackingWith(enabled:sensitivity:mode:minimumPeakIntensity:minimumPeakHeight:));

@end

NS_ASSUME_NONNULL_END
