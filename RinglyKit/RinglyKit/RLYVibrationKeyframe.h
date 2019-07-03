#import "RLYVibration.h"

/**
 * Represents a vibration keyframe in a `RLYKeyframeCommand`.
 */
RINGLYKIT_FINAL @interface RLYVibrationKeyframe : NSObject

#pragma mark - Initialization

/**
 *  `+new` is unavailable, use the designated initializer instead.
 */
+(instancetype)new NS_UNAVAILABLE;

/**
 *  `-init` is unavailable, use the designated initializer instead.
 */
-(instancetype)init NS_UNAVAILABLE;

/**
 *  Initializes a vibration keyframe.
 *
 *  @param timestamp         The timestamp of the keyframe.
 *  @param vibrationPower    The vibration power of the keyframe.
 *  @param interpolateToNext Whether or not to interpolate the transition to the next keyframe.
 */
-(instancetype)initWithTimestamp:(RLYKeyframeTimestamp)timestamp
                  vibrationPower:(RLYVibrationPower)vibrationPower
               interpolateToNext:(BOOL)interpolateToNext NS_DESIGNATED_INITIALIZER;

#pragma mark - Properties

/**
 *  The timestamp of the keyframe.
 */
@property (nonatomic, readonly) RLYKeyframeTimestamp timestamp;

/**
 *  The vibration power of the keyframe.
 */
@property (nonatomic, readonly) RLYVibrationPower vibrationPower;

/**
 *  Whether or not to interpolate the transition to the next keyframe.
 */
@property (nonatomic, readonly) BOOL interpolateToNext;

@end
