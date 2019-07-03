#import "RLYVibration.h"

#pragma mark - Vibrations
uint8_t RLYVibrationToCount(RLYVibration vibration)
{
    return vibration;
}

RLYVibration RLYVibrationFromCount(uint8_t count)
{
    return MIN(RLYVibrationFourPulses, (RLYVibration)count);
}

NSString *__nonnull RLYVibrationToString(RLYVibration vibration)
{
    switch (vibration)
    {
        case RLYVibrationOnePulse:
            return @"One";
            
        case RLYVibrationTwoPulses:
            return @"Two";
            
        case RLYVibrationThreePulses:
            return @"Three";
            
        case RLYVibrationFourPulses:
            return @"Four";
            
        default:
            return @"None";
    }
}
