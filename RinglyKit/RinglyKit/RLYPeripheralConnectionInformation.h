#import <CoreBluetooth/CoreBluetooth.h>

/**
 *  Contains properties describing the current state of the peripheral's connection.
 */
@protocol RLYPeripheralConnectionInformation <NSObject>

#pragma mark - State

/**
 *  The current state of the peripheral.
 */
@property (nonatomic, readonly) CBPeripheralState state;

#pragma mark - Connection

/**
 *  `YES` if the peripheral is connected to the phone, otherwise `NO`.
 */
@property (nonatomic, readonly, getter=isConnected) BOOL connected;

/**
 *  `YES` if the peripheral is connecting to the phone, otherwise `NO`.
 */
@property (nonatomic, readonly, getter=isConnecting) BOOL connecting;

/**
 *  `YES` if the peripheral is disconnected from the phone, otherwise `NO`.
 */
@property (nonatomic, readonly, getter=isDisconnected) BOOL disconnected;

#pragma mark - Shutdown

/**
 *  The last shutdown reason for the peripheral. When the peripheral connects, this property is automatically set to
 *  `RLYPeripheralShutdownReasonNone`.
 */
@property (nonatomic, readonly) RLYPeripheralShutdownReason lastShutdownReason;

#pragma mark - Pairing

/**
 *  The current pair state of the peripheral. The values of this property are documented in the `RLYPeripheralPairState`
 *  enumeration.
 */
@property (nonatomic, readonly) RLYPeripheralPairState pairState;

/**
 *  `YES` if the device is believed to be currently paired. Otherwise, `NO`.
 *
 *  In almost all cases, this will be correct. Peripherals that bond with the device are considered paired once they
 *  have sent a message to confirm this. Additionally, peripherals that are retrieved and are already connected are
 *  assumed to be paired. However, some inconsistencies can potentially arise.
 *
 *  This property is derived from the `pairState` property.
 *
 *  @see pairState
 */
@property (nonatomic, readonly, getter=isPaired) BOOL paired;

/**
 *  The current frame state of the peripheral
 *
 */
@property (nonatomic, readonly) RLYPeripheralFramesState framesState;

@end
