#import "RLYCommand.h"
#import "RLYDefines.h"

/**
 *  Enumerates the supported commands.
 */
typedef NS_ENUM(uint8_t, RLYCommandTypePreset)
{
    /**
     *  No command.
     */
    RLYCommandTypePresetNone = 0,
    
    /**
     *  Flash the LED and vibrate the peripheral.
     */
    RLYCommandTypePresetLEDVibration = 1,
    
    /**
     *  Reset the peripheral.
     */
    RLYCommandTypePresetFirmwareReset = 2,
    
    /**
     *  Send the peripheral into DFU mode.
     */
    RLYCommandTypePresetDFU = 3,
    
    /**
     *  Send the ring into hibernate mode - cannot be woken up until it is placed in a charger.
     */
    RLYCommandTypePresetDeepSleep = 4,
    
    /**
     *  Clear the ring's bond.
     */
    RLYCommandTypePresetClearBonds = 5,
    
    /**
     *  Alter the ring's advertising name.
     */
    RLYCommandTypePresetAdvertisingName = 6,
    
    /**
     *  Inform the ring of the mobile OS it is connected to.
     */
    RLYCommandTypePresetMobileOS = 7,
    
    /**
     *  Inform the ring of the current date and time.
     */
    RLYCommandTypePresetDateTime = 8,
    
    /**
     *  Enable or disable charging on the ring.
     */
    RLYCommandTypePresetChargeMode = 9,
    
    /**
     *  Alter the ring's sleep behavior.
     */
    RLYCommandTypePresetSleepMode = 10,
    
    /**
     *  Perform a logging query.
     */
    RLYCommandTypePresetLoggingQuery = 11,
    
    /**
     *   Send device into an MFG test application.
     */
    RLYCommandTypePresetRFScanTestAppSwitch = 12,
    
    /**
     *  Alter the ring's disconnect vibration behavior.
     */
    RLYCommandTypePresetDisconnectVibration = 13,
    
    /**
     *  Alter the ring's connection LED behavior.
     */
    RLYCommandTypePresetConnectionLED = 14,
    
    /**
     *  Set the hardware version string.
     */
    RLYCommandTypePresetHardwareVersion = 15,
    
    /**
     *  Set the click parameters.
     */
    RLYCommandTypePresetTapParameters = 16,
    
    /**
     *  Update an application notification configuration.
     */
    RLYCommandTypePresetApplicationSettings = 18,
    
    /**
     *  Update a contact notification configuration.
     */
    RLYCommandTypePresetContactSettings = 19,
    
    /**
     *  Update the contacts behavior.
     */
    RLYCommandTypePresetContactsMode = 20,
    
    /**
     *  Enables or disables the app responding to a connection LED request.
     */
    RLYCommandTypePresetConnectionLEDResponse = 22,
    
    /**
     *  Enables or disables the ANCS timeout alert.
     */
    RLYCommandTypePresetANCSTimeoutAlert = 23,
    
    /**
     *  Performs a keyframe-based LED and vibration action.
     */
    RLYCommandTypePresetKeyframe = 25,
    
    /**
     *  Alter the ring's notification pin LED behavior.
     */
    RLYCommandTypePresetNotificationPinLED = 26,
};

/**
 *  A data representation of the command.
 *
 *  @param command The command.
 */
RINGLYKIT_EXTERN NSData *RLYCommandDataRepresentation(id<RLYCommand> command);
