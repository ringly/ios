#import <Foundation/Foundation.h>
#import "RLYDefines.h"

/**
 *  Enumerates the supported modes of settings commands.
 */
typedef NS_ENUM(uint8_t, RLYSettingsCommandMode)
{
    /**
     *  Adds or updates a setting.
     */
    RLYSettingsCommandModeAdd,

    /**
     *  Deletes a setting.
     */
    RLYSettingsCommandModeDelete
};

/**
 *  Converts the settings command mode to a string representation.
 *
 *  @param settingsCommandMode The settings command mode.
 */
RINGLYKIT_EXTERN NSString *RLYSettingsCommandModeToString(RLYSettingsCommandMode settingsCommandMode);
