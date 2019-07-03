#import "RLYColor.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents a color keyframe in a `RLYKeyframeCommand`.
 */
RINGLYKIT_FINAL @interface RLYColorKeyframe : NSObject

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
 *  Initializes a color keyframe.
 *
 *  @param timestamp         The timestamp of the keyframe.
 *  @param color             The color of the keyframe.
 *  @param interpolateToNext Whether or not to interpolate the transition to the next keyframe.
 */
-(instancetype)initWithTimestamp:(RLYKeyframeTimestamp)timestamp
                           color:(RLYColor)color
               interpolateToNext:(BOOL)interpolateToNext NS_DESIGNATED_INITIALIZER;

#pragma mark - Properties

/**
 *  The timestamp of the keyframe.
 */
@property (nonatomic, readonly) RLYKeyframeTimestamp timestamp;

/**
 *  The color of the keyframe.
 */
@property (nonatomic, readonly) RLYColor color;

/**
 *  Whether or not to interpolate the transition to the next keyframe.
 */
@property (nonatomic, readonly) BOOL interpolateToNext;

@end

NS_ASSUME_NONNULL_END
