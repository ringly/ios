#import <RinglyKit/RLYPeripheral.h>

NS_ASSUME_NONNULL_BEGIN

@interface RLYPeripheral ()

#pragma mark - Peripherals

/**
 *  Retrieves a `RLYPeripheral` object, if possible.
 *
 *  @param CBPeripheral The Core Bluetooth peripheral that this object should wrap. This object will claim the
 *  peripheral's `delegate` property.
 *  @param assumePaired If `YES`, we can assume the peripheral is bonded. This should only be used with peripherals that
 *  are not being newly paired.
 *
 *  @return If the specified `CBPeripheral` is Ringly peripheral, a `RLYPeripheral` instance. Otherwise, `nil`.
 */
+(nullable instancetype)peripheralForCBPeripheral:(CBPeripheral*)CBPeripheral
                                     assumePaired:(BOOL)assumePaired
                              centralManagerState:(CBCentralManagerState)centralManagerState;

/**
 *  Enumerates the currently allocated peripherals, executing the block for each one.
 *
 *  @param block A block.
 */
+(void)enumerateKnownPeripherals:(void(^)(RLYPeripheral *peripheral))block;

#pragma mark - Core Bluetooth

/**
 *  The Core Bluetooth peripheral wrapped by this object.
 */
@property (nonatomic, readonly, strong) CBPeripheral *CBPeripheral;

/**
 *  The current central manager state.
 */
@property (nonatomic) CBCentralManagerState centralManagerState;

#pragma mark - Pair State

/**
 *  Allows internal classes to modify the `pairState` state of the peripheral.
 */
@property (nonatomic) RLYPeripheralPairState pairState;


@end

NS_ASSUME_NONNULL_END
