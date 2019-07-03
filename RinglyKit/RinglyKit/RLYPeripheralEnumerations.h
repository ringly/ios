#import <Foundation/Foundation.h>
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Battery State

/**
 *  Enumerates the possible states of the peripheral's battery.
 */
typedef NS_ENUM(NSInteger, RLYPeripheralBatteryState)
{
    /**
     *  The batter is not charging - normal use.
     */
    RLYPeripheralBatteryStateNotCharging = 0,
    
    /**
     *  The battery is charging.
     */
    RLYPeripheralBatteryStateCharging = 1,
    
    /**
     *  The battery is fully charged.
     */
    RLYPeripheralBatteryStateCharged = 2,
    
    /**
     *  The battery state was invalid.
     */
    RLYPeripheralBatteryStateError = 3
};

/**
 *  Returns a string representation of the battery state.
 *
 *  @param state The battery state.
 */
RINGLYKIT_EXTERN NSString *RLYPeripheralBatteryStateToString(RLYPeripheralBatteryState state);

#pragma mark - Feature Support

/**
 *  Informs the user whether or not a feature is available.
 */
typedef NS_ENUM(NSInteger, RLYPeripheralFeatureSupport)
{
    /**
     *  Support for the feature has not been determined yet. For example, we may be waiting for the characteristics of
     *  a Bluetooth service to be reported, so that we can determine whether or not a specific characteristic exists.
     */
    RLYPeripheralFeatureSupportUndetermined,
    
    /**
     *  The feature is unsupported.
     */
    RLYPeripheralFeatureSupportUnsupported,
    
    /**
     *  The feature is supported.
     */
    RLYPeripheralFeatureSupportSupported
};

#pragma mark - Pair State

/**
 *  Enumerates the possible pair states of a peripheral.
 */
typedef NS_ENUM(NSInteger, RLYPeripheralPairState)
{
    /**
     *  The peripheral has been assumed to be unpaired. This is the default state when a peripheral is discovered.
     */
    RLYPeripheralPairStateAssumedUnpaired,
    
    /**
     *  The peripheral has been verified to be unpaired.
     */
    RLYPeripheralPairStateUnpaired,
    
    /**
     *  The peripheral has been assumed to be paired. This is the default when a connected peripheral is found.
     */
    RLYPeripheralPairStateAssumedPaired,
    
    /**
     *  The peripheral has been verified to be paired.
     */
    RLYPeripheralPairStatePaired
};

/**
 *  Returns `YES` if the pair state is "paired" or "assumed paired".
 *
 *  @param pairState The pair state.
 */
RINGLYKIT_EXTERN BOOL RLYPeripheralPairStateIsPaired(RLYPeripheralPairState pairState);

/**
 *  Converts the pair state to a string representation.
 *
 *  @param pairState The pair state.
 */
RINGLYKIT_EXTERN NSString *RLYPeripheralPairStateToString(RLYPeripheralPairState pairState);

#pragma mark - ANCS Notification Mode

/**
 *  Enumerates the possible ANCS notification modes of a peripheral.
 */
typedef NS_ENUM(NSInteger, RLYPeripheralANCSNotificationMode)
{
    /**
     *  The peripheral's ANCS notification mode has not been determined.
     */
    RLYPeripheralANCSNotificationModeUnknown,
    
    /**
     *  The peripheral cannot automatically perform behaviors, and notifications will need to be processed on the phone.
     */
    RLYPeripheralANCSNotificationModePhone,
    
    /**
     *  The peripheral will automatically perform behaviors.
     */
    RLYPeripheralANCSNotificationModeAutomatic
};

#pragma mark - Style

/**
 *  Enumerates the "style" of peripherals.
 */
typedef NS_ENUM(NSInteger, RLYPeripheralStyle)
{
    /**
     *  The style has not been determined yet. This is different than the style being *invalid* — the style will
     *  eventually be determined.
     */
    RLYPeripheralStyleUndetermined = 0,
    
    /**
     *  Stargaze.
     */
    RLYPeripheralStyleStargaze,
    
    /**
     *  Wine Bar.
     */
    RLYPeripheralStyleWineBar,
    
    /**
     *  Daydream.
     */
    RLYPeripheralStyleDaydream,
    
    /**
     *  Into the Woods.
     */
    RLYPeripheralStyleIntoTheWoods,
    
    /**
     *  Dive Bar.
     */
    RLYPeripheralStyleDiveBar,
    
    /**
     *  Out to Sea.
     */
    RLYPeripheralStyleOutToSea,
    
    /**
     *  Daybreak.
     */
    RLYPeripheralStyleDaybreak,
    
    /**
     *  Opening Night.
     */
    RLYPeripheralStyleOpeningNight,
    
    /**
     *  Wanderlust.
     */
    RLYPeripheralStyleWanderlust,

    /**
     *  The gold version of “Disrupt”, a special-edition Mr. Robot ring.
     */
    RLYPeripheralStyleDisruptGold,

    /**
     *  The rhodium version of “Disrupt”, a special-edition Mr. Robot ring.
     */
    RLYPeripheralStyleDisruptRhodium,

    /**
     *  Road Trip.
     */
    RLYPeripheralStyleRoadTrip,

    /**
     *  Boardwalk.
     */
    RLYPeripheralStyleBoardwalk,

    /**
     *  Backstage.
     */
    RLYPeripheralStyleBackstage,

    /**
     *  Lakeside.
     */
    RLYPeripheralStyleLakeside,

    /**
     *  Photo Booth.
     */
    RLYPeripheralStylePhotoBooth,

    /**
     *  Rendezvous.
     */
    RLYPeripheralStyleRendezvous,
    
    /**
     *  Canal White.
     */
    RLYPeripheralStyleGo01,
    
    /**
     *  Canal Black.
     */
    RLYPeripheralStyleGo02,
    
    RLYPeripheralStyleRose,
    RLYPeripheralStyleJets,
    RLYPeripheralStyleRide,
    RLYPeripheralStyleBonv,
    RLYPeripheralStyleDate,
    RLYPeripheralStyleHour,
    RLYPeripheralStyleMoon,
    RLYPeripheralStyleTide,
    RLYPeripheralStyleDay2,
    
    /**
     *  An unknown or invalid style.
     */
    RLYPeripheralStyleInvalid = -1
};

/**
 *  Converts a `RLYPeripheralStyle` from a short name (i.e. `DAYD`, `STAR`).
 *
 *  @param shortName The short name to convert. If `nil`, the result will be `RLYPeripheralStyleUndetermined`, not
 *  `RLYPeripheralStyleInvalid`, which is reserved for a non-`nil` string value that does not match any current
 *  style.
 */
RINGLYKIT_EXTERN RLYPeripheralStyle RLYPeripheralStyleFromShortName(NSString *__nullable shortName);

/**
 *  Returns a user-displayable string for the name of a peripheral style. For unknown or invalid styles, this will be
 *  `nil`.
 *
 *  @param style The peripheral style.
 */
RINGLYKIT_EXTERN NSString *__nullable RLYPeripheralStyleName(RLYPeripheralStyle style);

/**
 *  Returns a short name for the specified peripheral name, if possible.
 *
 *  @param name The peripheral name to convert.
 */
RINGLYKIT_EXTERN NSString *__nullable RLYPeripheralShortNameFromName(NSString *__nullable name);

#pragma mark - Band

/**
 *  Enumerates the styles used for peripheral bands.
 */
typedef NS_ENUM(NSInteger, RLYPeripheralBand)
{
    /**
     *  The band has not been determined yet. This is different than the band being *invalid* — the band will
     *  eventually be determined.
     */
    RLYPeripheralBandUndetermined = 0,

    /**
     *  A gold metal band.
     */
    RLYPeripheralBandGold,

    /**
     *  A silver metal band.
     */
    RLYPeripheralBandSilver,

    /**
     *  A rhodium metal band.
     */
    RLYPeripheralBandRhodium,
    

    /**
     *  An unknown or invalid band.
     */
    RLYPeripheralBandInvalid = -1
};

/**
 *  Converts a peripheral style to a peripheral band.
 *
 *  @param style The peripheral style.
 */
RINGLYKIT_EXTERN RLYPeripheralBand RLYPeripheralBandFromStyle(RLYPeripheralStyle style);

#pragma mark - Stone

/**
 *  Enumerates the styles of stones used by peripherals.
 */
typedef NS_ENUM(NSInteger, RLYPeripheralStone)
{
    /**
     *  The stone has not been determined yet. This is different than the stone being *invalid* — the stone will
     *  eventually be determined.
     */
    RLYPeripheralStoneUndetermined = 0,

    /**
     *  Black Onyx.
     */
    RLYPeripheralStoneBlackOnyx,

    /**
     *  Blue Lace Agate.
     */
    RLYPeripheralStoneBlueLaceAgate,

    /**
     *  Emerald.
     */
    RLYPeripheralStoneEmerald,

    /**
     *  Labradorite.
     */
    RLYPeripheralStoneLabradorite,

    /**
     *  Lapis.
     */
    RLYPeripheralStoneLapis,

    /**
     *  Pink Chalecedony.
     */
    RLYPeripheralStonePinkChalecedony,

    /**
     *  Pink Sapphire.
     */
    RLYPeripheralStonePinkSapphire,

    /**
     *  Snowflake Obsidian.
     */
    RLYPeripheralStoneSnowflakeObsidian,

    /**
     *  Tourmalated Quartz.
     */
    RLYPeripheralStoneTourmalatedQuartz,

    /**
     *  Rainbow Moonstone.
     */
    RLYPeripheralStoneRainbowMoonstone,

    /**
     *  An unknown or invalid stone.
     */
    RLYPeripheralStoneInvalid = -1
};

/**
 *  Returns a user-displayable string or the name of a peripheral stone. For unknown or invalid stones, this will be
 *  `nil`.
 *
 *  @param stone The peripheral stone.
 */
RINGLYKIT_EXTERN NSString *__nullable RLYPeripheralStoneName(RLYPeripheralStone stone);

/**
 *  Converts a peripheral style to a peripheral stone.
 *
 *  @param style The peripheral style.
 */
RINGLYKIT_EXTERN RLYPeripheralStone RLYPeripheralStoneFromStyle(RLYPeripheralStyle style);

#pragma mark - Type

/**
 *  Enumerates the types of peripherals.
 */
typedef NS_ENUM(NSInteger, RLYPeripheralType)
{
    /**
     *  The type has not been determined yet. This is different than the type being *invalid* — the type will eventually
     *  be determined.
     */
    RLYPeripheralTypeUndetermined = 0,

    /**
     *  A ring.
     */
    RLYPeripheralTypeRing,

    /**
     *  A bracelet.
     */
    RLYPeripheralTypeBracelet,

    /**
     *  An unknown or invalid style.
     */
    RLYPeripheralTypeInvalid = -1
};


/**
 *  Converts a peripheral style to a peripheral type.
 *
 *  @param style The peripheral style.
 */
RINGLYKIT_EXTERN RLYPeripheralType RLYPeripheralTypeFromStyle(RLYPeripheralStyle style);

#pragma mark - Shutdown Reason

/**
 *  Enumerates the possible reasons that a peripheral can shut down for.
 */
typedef NS_ENUM(NSInteger, RLYPeripheralShutdownReason)
{
    /**
     *  No shutdown reason.
     */
    RLYPeripheralShutdownReasonNone,
    
    /**
     *  The peripheral is shutting down due to low battery.
     */
    RLYPeripheralShutdownReasonBattery,
    
    /**
     *  The peripheral is going to sleep because it has been idle (not moved) for a while.
     */
    RLYPeripheralShutdownReasonIdle
};

typedef NS_ENUM(NSInteger, RLYPeripheralFramesState)
{
    /**
     *  Not started
     */
    RLYPeripheralFramesStateNotStarted,
    
    /**
     *  Started
     */
    RLYPeripheralFramesStateStarted,
    
    /**
     *  Ended
     */
    RLYPeripheralFramesStateEnded
};

NS_ASSUME_NONNULL_END
