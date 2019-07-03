#import <stdint.h>

#if defined(__cplusplus)
#define RINGLYKIT_EXTERN extern "C"
#else
#define RINGLYKIT_EXTERN extern
#endif

#if defined(__has_attribute) && __has_attribute(objc_subclassing_restricted)
#define RINGLYKIT_FINAL __attribute__((objc_subclassing_restricted))
#else
#define RINGLYKIT_FINAL
#endif

/**
 *  The timestamp of a keyframe value (`RLYColorKeyframe` & `RLYVibrationKeyframe`), an eight-bit unsigned integer.
 */
typedef uint8_t RLYKeyframeTimestamp;

/**
 *  The vibration power value for a peripheral's motor, an eight-bit unsigned integer.
 */
typedef uint8_t RLYVibrationPower;
