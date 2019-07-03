#import "RLYCentralDiscovery.h"
#import "RLYCentralObserver.h"
#import "RLYPeripheral.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Provides access to Ringly peripherals.
 
 All `@property` values can be observed with KVO.
 */
RINGLYKIT_FINAL @interface RLYCentral : NSObject

#pragma mark - Initialization

/**
 *  Initializes a `RLYCentral` without a restore identifier.
 */
-(instancetype)init;

/**
 *  Initializes a `RLYCentral`.
 *
 *  If the `bluetooth-central` background mode will be used with the Ringly peripheral, a restore identifier should be
 *  provided.
 *
 *  @param restoreIdentifier The restore identifier to use for the central's `CBCentralManager`. This
 *                           parameter is optional - if `nil` is passed, a restore identifier will not be used.
 *                           This parameter has no effect on OS X.
 */
-(instancetype)initWithCBCentralManagerRestoreIdentifier:(nullable NSString*)restoreIdentifier NS_DESIGNATED_INITIALIZER;

#pragma mark - Observers

/**
 *  Adds an observer.
 *
 *  @param observer The observer to add.
 */
-(void)addObserver:(id<RLYCentralObserver>)observer NS_SWIFT_NAME(add(observer:));

/**
 *  Removes an observer.
 *
 *  @param observer The observer to remove.
 */
-(void)removeObserver:(id<RLYCentralObserver>)observer NS_SWIFT_NAME(remove(observer:));

#pragma mark - Bluetooth

/**
 *  Prompts the user to power on Bluetooth, by showing the system alert.
 *
 *  @return `YES` if the user was prompted. `NO` if Bluetooth was already powered on.
 */
-(BOOL)promptToPowerOnBluetooth;

/**
 *  The current state of the central's `CBCentralManager`.
 */
@property (nonatomic, readonly) CBCentralManagerState managerState;

/**
 *  Returns `YES` if Bluetooth is currently powered on.
 */
@property (nonatomic, readonly, getter=isPoweredOn) BOOL poweredOn;

/**
 *  Returns `YES` if Bluetooth is currently powered off.
 */
@property (nonatomic, readonly, getter=isPoweredOff) BOOL poweredOff;

/**
 *  Returns `YES` if Bluetooth is unsupported on this device.
 */
@property (nonatomic, readonly, getter=isUnsupported) BOOL unsupported;

#pragma mark - Peripheral Connections

/**
 *  Instructs the service to connect to a peripheral.
 *
 *  @param peripheral The peripheral to connect to.
 */
-(void)connectToPeripheral:(RLYPeripheral*)peripheral NS_SWIFT_NAME(connect(to:));

/**
 *  Disconnects from a peripheral, or cancels a pending connection.
 *
 *  @param peripheral The peripheral to disconnect from.
 */
-(void)cancelPeripheralConnection:(RLYPeripheral*)peripheral NS_SWIFT_NAME(cancelConnection(to:));

#pragma mark - Retrieving Connected Peripherals

/**
 *  Retrieves all connected peripherals.
 */
-(NSArray<RLYPeripheral*>*)retrieveConnectedPeripherals;

/**
 *  Retrieves the connected peripheral with the specified UUID, if one exists.
 *
 *  @param UUID The UUID.
 */
-(nullable RLYPeripheral*)retrieveConnectedPeripheralWithUUID:(NSUUID*)UUID
    NS_SWIFT_NAME(retrieveConnectedPeripheral(UUID:));

#pragma mark - Retrieving Peripherals

/**
 *  Retrieves an array of known peripherals by their identifiers.
 *
 *  @param identifiers  The identifiers to retrieve peripherals for.
 *  @param assumePaired If `YES`, the peripherals will be assumed to be paired.
 */
-(NSArray<RLYPeripheral*>*)retrievePeripheralsWithIdentifiers:(NSArray<NSUUID*>*)identifiers
                                                 assumePaired:(BOOL)assumePaired
    NS_SWIFT_NAME(retrievePeripheralsWith(identifiers:assumedPaired:));

#pragma mark - Peripheral Discovery

/**
 *  Begins searching for peripherals.
 */
-(void)startDiscoveringPeripherals;

/**
 *  Stops searching for peripherals.
 */
-(void)stopDiscoveringPeripherals;

/**
 *  The currently discovered peripherals and recovery peripherals.
 *
 *  If currently discovering, this value will be non-`nil`, although its array properties may be empty. If not currently
 *  discovering, the value will always be `nil`.
 */
@property (nullable, nonatomic, readonly, strong) RLYCentralDiscovery *discovery;

@end

NS_ASSUME_NONNULL_END
