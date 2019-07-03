#import "RLYANCSNotification.h"
#import "RLYActivityTrackingUpdate.h"
#import "RLYColor.h"
#import "RLYCommand.h"
#import "RLYVibration.h"

NS_ASSUME_NONNULL_BEGIN

@class RLYPeripheral;

/**
 *  Provides notifications to observers of a `RLYPeripheral` instance.
 */
@protocol RLYPeripheralObserver <NSObject>

@optional

#pragma mark - ANCS Notifications

/**
 *  Notifies the observer that the peripheral has received an ANCS notification.
 *
 *  @param peripheral  The peripheral.
 *  @param ANCSNotification The message that was received.
 */
-(void)peripheral:(RLYPeripheral*)peripheral didReceiveANCSNotification:(RLYANCSNotification*)ANCSNotification;

#pragma mark - Messages

/**
 *  Notifies the observer that the peripheral has been tapped by the user.
 *
 *  @param peripheral The peripheral.
 *  @param tapCount   The number of taps.
 */
-(void)peripheral:(RLYPeripheral*)peripheral receivedTapsWithCount:(NSUInteger)tapCount;

/**
 *  Notifies the observer that the peripheral is shutting down.
 *
 *  @param peripheral The peripheral.
 *  @param reason     The reason that the peripheral is shutting down.
 */
-(void)peripheral:(RLYPeripheral*)peripheral isShuttingDownWithReason:(RLYPeripheralShutdownReason)reason;

/**
 *  Notifies the observer that the peripheral confirmed an application setting.
 *
 *  @param peripheral The peripheral.
 *  @param fragment   The string fragment provided by the peripheral.
 *  @param color      The LED color sent by the peripheral.
 *  @param vibration  The vibration sent by the peripheral.
 */
-(void)peripheral:(RLYPeripheral*)peripheral confirmedApplicationSettingWithFragment:(NSString*)fragment
            color:(RLYColor)color
        vibration:(RLYVibration)vibration;

/**
 *  Notifies the observer that the peripheral confirmed that an application setting was deleted.
 *
 *  @param peripheral The peripheral.
 */
-(void)peripheralConfirmedApplicationSettingDeleted:(RLYPeripheral*)peripheral;

/**
 *  Notifies the observer that the peripheral confirmed that the application settings were cleared.
 *
 *  @param peripheral The peripheral.
 */
-(void)peripheralConfirmedApplicationSettingsCleared:(RLYPeripheral*)peripheral;

/**
 *  Notifies the observer that the peripheral failed to set an application setting.
 *
 *  @param peripheral The peripheral.
 *  @param fragment   The string fragment provided by the peripheral.
 */
-(void)peripheral:(RLYPeripheral*)peripheral failedApplicationSettingWithFragment:(NSString*)fragment;

/**
 *  Notifies the observer that the peripheral confirmed a contact setting.
 *
 *  @param peripheral The peripheral.
 *  @param fragment   The string fragment provided by the peripheral.
 *  @param color      The LED color sent by the peripheral.
 */
-(void)peripheral:(RLYPeripheral*)peripheral confirmedContactSettingWithFragment:(NSString*)fragment
            color:(RLYColor)color;

/**
 *  Notifies the observer that the peripheral confirmed that a contact setting was deleted.
 *
 *  @param peripheral The peripheral.
 */
-(void)peripheralConfirmedContactSettingDeleted:(RLYPeripheral*)peripheral;

/**
 *  Notifies the observer that the peripheral confirmed that the contact settings were cleared.
 *
 *  @param peripheral The peripheral.
 */
-(void)peripheralConfirmedContactSettingsCleared:(RLYPeripheral*)peripheral;

/**
 *  Notifies the observer that the peripheral failed to set a contact setting.
 *
 *  @param peripheral The peripheral.
 *  @param fragment   The string fragment provided by the peripheral.
 */
-(void)peripheral:(RLYPeripheral*)peripheral failedContactSettingWithFragment:(NSString*)fragment;

/**
 *  Notifies the observer that the peripheral encountered an application error.
 *
 *  @param peripheral The peripheral.
 *  @param filename   The filename in which the error occurred. This string is limited to 9 bytes.
 *  @param lineNumber The line number at which the error occurred within `filename`.
 */
-(void)peripheral:(RLYPeripheral*)peripheral encounteredApplicationErrorWithCode:(NSUInteger)code
       lineNumber:(NSUInteger)lineNumber
         filename:(NSString*)filename;


/**
 *  Notifies the observer that the peripheral received a message that is not supported by `RLYPeripheral`.
 *
 *  @param peripheral The peripheral.
 *  @param type       The message type.
 *  @param data       The message data, not including the type.
 */
-(void)peripheral:(RLYPeripheral*)peripheral receivedUnsupportedMessageType:(uint8_t)type withData:(NSData*)data;

#pragma mark - Commands

/**
 *  Notifies the observer that a `RLYCommand` will be written to the peripheral.
 *
 *  This callback will be followed by `-peripheral:didWriteCommand:` or `-peripheral:failedToWriteCommand:withError:`.
 *
 *  @param peripheral The peripheral.
 *  @param command    The command that will be written to the peripheral.
 */
-(void)peripheral:(RLYPeripheral*)peripheral willWriteCommand:(id<RLYCommand>)command;

/**
 *  Notifies the observer that a `RLYCommand` was written to the peripheral.
 *
 *  @param peripheral The peripheral.
 *  @param command    The command that was written to the peripheral.
 */
-(void)peripheral:(RLYPeripheral*)peripheral didWriteCommand:(id<RLYCommand>)command;

/**
 *  Notifies the observer that a `RLYCommand` was not written to the peripheral.
 *
 *  @param peripheral The peripheral.
 *  @param command    The command that was not written to the peripheral.
 *  @param error      The associated error object.
 */
-(void)peripheral:(RLYPeripheral*)peripheral failedToWriteCommand:(id<RLYCommand>)command withError:(NSError*)error;

#pragma mark - Activity Tracking

/**
 *  Notifies the observer that activity tracking data was read from the peripheral.
 *
 *  @param peripheral             The peripheral.
 *  @param activityTrackingUpdate The activity tracking update that was read.
 */
-(void)peripheral:(RLYPeripheral*)peripheral readActivityTrackingUpdate:(RLYActivityTrackingUpdate*)activityTrackingUpdate;

/**
 *  Notifies the observer that an error was encountered while reading activity tracking updates from the peripheral.
 *
 *  This message may be sent in sequence with notifications of successful update reads - it does not imply failure of
 *  the entire activity data reading process.
 *
 *  @param peripheral The peripheral.
 *  @param error      The error that occured.
 */
-(void)peripheral:(RLYPeripheral*)peripheral encounteredErrorWhileReadingActivityTrackingUpdates:(NSError*)error;

/**
 *  Notifies the observer that the peripheral completed reading activity updates.
 *
 *  @param peripheral The peripheral.
 */
-(void)peripheralCompletedReadingActivityData:(RLYPeripheral*)peripheral;

#pragma mark - Flash Logging

/**
 Notifies the observer that flash log data was read from the peripheral. A 0-length data indicates the end of a read.

 @param peripheral The peripheral.
 @param data The data that was read.
 */
-(void)peripheral:(RLYPeripheral*)peripheral readFlashLogData:(NSData*)data;

@end

NS_ASSUME_NONNULL_END
