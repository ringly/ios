#import "RLYPeripheralEnumerations.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Adds functionality to observe a peripheral's ANCS notification mode.
 *
 *  Older peripherals cannot perform behavior automatically upon receiving a notification, and must relay the
 *  notification to a central device, which determines the behavior and instructs the peripheral to perform it. Newer
 *  peripherals have sufficient memory and processing power to perform this automatically, without relying on a central
 *  device.
 */
@protocol RLYPeripheralANCSNotificationModeInformation <NSObject>

#pragma mark - ANCS Notification Mode

/**
 *  The ANCS notification mode of the peripheral.
 */
@property (nonatomic, readonly) RLYPeripheralANCSNotificationMode ANCSNotificationMode;

@end

NS_ASSUME_NONNULL_END
