#import <Foundation/Foundation.h>

/**
 *  Enumerates the messages that can be received by `RLYPeripheral`.
 */
typedef NS_ENUM(uint8_t, RLYPeripheralMessageType)
{
    /**
     *  The peripheral was tapped by the user. The message will include the number of taps as an ASCII number.
     */
    RLYPeripheralMessageTypeTap = 48,
    
    /**
     *  The peripheral will go to sleep.
     */
    RLYPeripheralMessageTypeSleepShutdown = 49,
    
    /**
     *  The peripheral will shut down due to low battery.
     */
    RLYPeripheralMessageTypeLowBatteryShutdown = 50,
    
    /**
     *  The peripheral completed bonding.
     */
    RLYPeripheralMessageTypeBonded = 51,
    
    /**
     *  A new ANCS v2 notification is available. The message will include the number of notification attributes and
     *  the number of application attributes, as comma-separated ASCII numbers.
     */
    RLYPeripheralMessageTypeNewANCSV2 = 4,
    
    /**
     *  The timer was triggered.
     */
    RLYPeripheralMessageTypeTimerTrigger = 5,
    
    /**
     * Keyframe command callback
    */
    RLYPeripheralMessageTypeKeyframeCallback = 11,
    
    /**
     *  An application setting was confirmed to succeed or fail.
     */
    RLYPeripheralMessageTypeApplicationSettingConfirmation = 6,
    
    /**
     *  A contact setting was confirmed to succeed or fail.
     */
    RLYPeripheralMessageTypeContactSettingConfirmation = 7,
    
    /**
     *  The peripheral confirmed that it is clearing its bond.
     */
    RLYPeripheralMessageTypeClearBondConfirmation = 57,
    
    /**
     *  The peripheral reset due to an application error. New data is available on the application error characteristic.
     */
    RLYPeripheralMessageTypeApplicationErrorReset = 8,
    
    /**
     *  The peripheral has a new GPIO pin report.
     */
    RLYPeripheralMessageTypeGPIOPinReport = 9
};
