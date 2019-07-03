#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RLYCentral, RLYPeripheral;

/**
 *  Provides notifications to observers of a `RLYCentral` instance.
 */
@protocol RLYCentralObserver <NSObject>

@optional

#pragma mark - Restoring State

/**
 *  Notifies the observer that the central restored peripherals.
 *
 *  @param central     The central.
 *  @param peripherals The restored peripherals.
 */
-(void)central:(RLYCentral*)central didRestorePeripherals:(NSArray<RLYPeripheral*>*)peripherals;

#pragma mark - Peripheral Connections

/**
 *  Notifies the observer that the central will attempt to connect to a peripheral.
 *
 *  @param central    The central.
 *  @param peripheral The peripheral. */
-(void)central:(RLYCentral*)central willConnectToPeripheral:(RLYPeripheral*)peripheral;

/**
 *  Notifies the observer that the central successfully connected to a peripheral.
 *
 *  @param central    The central.
 *  @param peripheral The peripheral.
 */
-(void)central:(RLYCentral*)central didConnectToPeripheral:(RLYPeripheral*)peripheral;

/**
 *  Notifies the observer that the central failed to connect to a peripheral.
 *
 *  @param central    The central.
 *  @param peripheral The peripheral.
 *  @param error      An error describing the connection failure, if available.
 */
-(void)central:(RLYCentral*)central didFailToConnectPeripheral:(RLYPeripheral*)peripheral withError:(nullable NSError*)error;

/**
 *  Notifies the observer that the central disconnected from the peripheral.
 *
 *  @param central    The central.
 *  @param peripheral The peripheral.
 *  @param error      An error describing the disconnection, if available.
 */
-(void)central:(RLYCentral*)central didDisconnectFromPeripheral:(RLYPeripheral*)peripheral withError:(nullable NSError*)error;

/**
 *  Notifies the observer that the user forgot a peripheral.
 *
 *  @param central    The central.
 *  @param peripheral The peripheral.
 */
-(void)central:(RLYCentral*)central userDidForgetPeripheral:(RLYPeripheral*)peripheral;

@end

NS_ASSUME_NONNULL_END
