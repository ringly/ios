#import <Foundation/Foundation.h>
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Enumerates the supported vibration modes for the Ringly device.
 */
typedef NS_ENUM(NSInteger, RLYVibration)
{
    /**
     *  No vibration.
     */
    RLYVibrationNone,
    
    /**
     *  One vibration pulse.
     */
    RLYVibrationOnePulse,
    
    /**
     *  Two vibration pulses.
     */
    RLYVibrationTwoPulses,
    
    /**
     *  Three vibration pulses.
     */
    RLYVibrationThreePulses,
    
    /**
     *  Four vibration pulses.
     */
    RLYVibrationFourPulses
};

/**
 *  Returns the number of vibration pulses for the specified `RLYVibration`.
 *
 *  @param vibration The vibration.
 */
RINGLYKIT_EXTERN uint8_t RLYVibrationToCount(RLYVibration vibration);

/**
 *  Returns a `RLYVibration` for the number of pulses specified by `count`.
 *
 *  @param count The number of pulses.
 */
RINGLYKIT_EXTERN RLYVibration RLYVibrationFromCount(uint8_t count);

/**
 *  Returns a string representation for a `RLYVibration`.
 *
 *  @param vibration The vibration.
 */
RINGLYKIT_EXTERN NSString *RLYVibrationToString(RLYVibration vibration);

NS_ASSUME_NONNULL_END
