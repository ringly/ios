#import "RLYCommand.h"
#import "RLYColorKeyframe.h"
#import "RLYVibrationKeyframe.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Instructs the peripheral to perform a keyframe-based LED and vibration pattern.
 *
 * The `RLYColorKeyframe` and `RLYVibrationKeyframe` classes are used to specify keyframes.
 */
RINGLYKIT_FINAL @interface RLYKeyframeCommand : NSObject <RLYCommand>

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
 *  Initializes a keyframe commands.
 *
 *  @param colorKeyframes       The LED keyframes to use.
 *  @param vibrationKeyframes The vibration keyframes to use.
 */
-(instancetype)initWithColorKeyframes:(NSArray<RLYColorKeyframe*>*)colorKeyframes
                   vibrationKeyframes:(NSArray<RLYVibrationKeyframe*>*)vibrationKeyframes
                          repeatCount:(uint8_t)repeatCount NS_DESIGNATED_INITIALIZER;

#pragma mark - Properties

/**
 *  The LED keyframes to use.
 */
@property (nonatomic, readonly, strong) NSArray<RLYColorKeyframe*> *colorKeyframes;

/**
 *  The vibration keyframes to use.
 */
@property (nonatomic, readonly, strong) NSArray<RLYVibrationKeyframe*> *vibrationKeyframes;

/**
  * Times to repeat the command
 */
@property (nonatomic, readonly, assign) uint8_t repeatCount;

@end

NS_ASSUME_NONNULL_END
