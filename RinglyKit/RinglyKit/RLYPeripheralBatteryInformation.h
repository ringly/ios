#import "RLYPeripheralEnumerations.h"

/**
 *  Contains properties describing the battery state of a peripheral.
 */
@protocol RLYPeripheralBatteryInformation <NSObject>

#pragma mark - Charge

/**
 *  Until this property is set to `YES`, the value of `batteryCharge` will be set, but not necessarily correctly (and,
 *  in most cases, it will be incorrect).
 *
 *  Therefore, when displaying the current charge value, one should watch this property as well, and avoid showing the
 *  charge state.
 *
 *  @see batteryCharge
 */
@property (nonatomic, readonly, getter=isBatteryChargeDetermined) BOOL batteryChargeDetermined;

/**
 *  The current charge value of the battery. This is an integer value from 0 to 100.
 *
 *  @see batteryChargeDetermined
 */
@property (nonatomic, readonly) NSInteger batteryCharge;

#pragma mark - State

/**
 *  Until this property is set to `YES`, the value of `batteryState` will be set, but not necessarily correctly.
 *
 *  @see batteryState
 */
@property (nonatomic, readonly, getter=isBatteryStateDetermined) BOOL batteryStateDetermined;

/**
 *  The current state of the battery.
 *
 *  @see batteryStateDetermined
 */
@property (nonatomic, readonly) RLYPeripheralBatteryState batteryState;

/**
 *  `YES` if the battery is actively charging. This value will be `NO` if the battery is fully charged, and thus no
 *  longer charging.
 */
@property (nonatomic, readonly, getter=isCharging) BOOL charging;

/**
 *  `YES` if the battery is charging, or is fully charged.
 */
@property (nonatomic, readonly, getter=isChargingOrCharged) BOOL chargingOrCharged;

@end
