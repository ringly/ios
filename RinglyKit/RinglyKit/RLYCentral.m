#import "RLYCentral.h"
#import "RLYCentral+Internal.h"
#import "RLYCentralDiscovery+Internal.h"
#import "RLYClearBondsCommand.h"
#import "RLYDefines+Internal.h"
#import "RLYFunctions.h"
#import "RLYMobileOSCommand.h"
#import "RLYObservers.h"
#import "RLYPeripheral+Internal.h"
#import "RLYRecoveryPeripheral+Internal.h"
#import "RLYUUID.h"
#import "RLYLogFunction.h"

@interface RLYCentral () <CBCentralManagerDelegate>

// observers
@property (nonatomic, readonly, strong) RLYObservers *observers;

// central manager
@property (nonatomic) CBCentralManagerState managerState;

// discovery
@property (nonatomic, strong) RLYCentralDiscovery *discovery;

@end

@implementation RLYCentral

_RLY_OBSERVABLE_BOILERPLATE(RLYCentralObserver, _observers)

#pragma mark - Initialization
-(instancetype)init
{
    return [self initWithCBCentralManagerRestoreIdentifier:nil];
}

-(instancetype)initWithCBCentralManagerRestoreIdentifier:(nullable NSString *)restoreIdentifier
{
    self = [super init];
    
    if (self)
    {
        _observers = [RLYObservers new];
        
        NSMutableDictionary *options = [NSMutableDictionary dictionaryWithCapacity:2];
        options[CBCentralManagerOptionShowPowerAlertKey] = @NO;
        
        #if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
        if (restoreIdentifier)
        {
            options[CBCentralManagerOptionRestoreIdentifierKey] = restoreIdentifier;
        }
        #endif
        
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:nil
                                                             options:options];
    }
    
    return self;
}

#pragma mark - Central Manager
-(BOOL)promptToPowerOnBluetooth
{
    if (self.poweredOff)
    {
        NSDictionary *options = @{ CBCentralManagerOptionShowPowerAlertKey: @YES };
        id __unused cm = [[CBCentralManager alloc] initWithDelegate:nil queue:nil options:options];
        return YES;
    }
    else
    {
        return NO;
    }
}

+(NSSet*)keyPathsForValuesAffectingPoweredOn
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYCentral, managerState)];
}

-(BOOL)isPoweredOn
{
    return _managerState == CBCentralManagerStatePoweredOn;
}

+(NSSet*)keyPathsForValuesAffectingPoweredOff
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYCentral, managerState)];
}

-(BOOL)isPoweredOff
{
    return _managerState == CBCentralManagerStatePoweredOff;
}

+(NSSet*)keyPathsForValuesAffectingUnsupported
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYCentral, managerState)];
}

-(BOOL)isUnsupported
{
    return _managerState == CBCentralManagerStateUnsupported;
}

#pragma mark - Peripherals
-(void)connectToPeripheral:(RLYPeripheral * __nonnull)peripheral
{
    if (peripheral.state != CBPeripheralStateConnected)
    {
        [_observers enumerateObservers:^(id<RLYCentralObserver> observer) {
            if ([observer respondsToSelector:@selector(central:willConnectToPeripheral:)])
            {
                [observer central:self willConnectToPeripheral:peripheral];
            }
        }];
        
        [_centralManager connectPeripheral:peripheral.CBPeripheral options:nil];
    }
}

-(void)cancelPeripheralConnection:(RLYPeripheral*)peripheral
{
    [_centralManager cancelPeripheralConnection:peripheral.CBPeripheral];
}

#pragma mark - Retrieving Connected Peripherals
-(nonnull NSArray*)retrieveConnectedPeripherals
{
    NSArray *foundPeripherals = [_centralManager retrieveConnectedPeripheralsWithServices:[RLYUUID allRinglyServiceUUIDs]];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:foundPeripherals.count];
    
    for (CBPeripheral *foundPeripheral in foundPeripherals)
    {
        if (RLYCBPeripheralIsRingly(foundPeripheral))
        {
            [array addObject:[RLYPeripheral peripheralForCBPeripheral:foundPeripheral
                                                         assumePaired:YES
                                                  centralManagerState:(CBCentralManagerState)_centralManager.state]];
        }
    }
    
    return array;
}

-(nullable RLYPeripheral*)retrieveConnectedPeripheralWithUUID:(NSUUID*)UUID
{
    NSArray *peripherals = [_centralManager retrieveConnectedPeripheralsWithServices:[RLYUUID allRinglyServiceUUIDs]];
    
    CBPeripheral *peripheral = RLYFirstMatching(peripherals, ^BOOL(CBPeripheral *peripheral) {
        return [peripheral.identifier isEqual:UUID];
    });
    
    return peripheral ? [RLYPeripheral peripheralForCBPeripheral:peripheral
                                                    assumePaired:YES
                                             centralManagerState:(CBCentralManagerState)_centralManager.state] : nil;
}

#pragma mark - Retrieving Peripherals
-(NSArray<RLYPeripheral*>*)retrievePeripheralsWithIdentifiers:(NSArray<NSUUID*>*)identifiers
                                                 assumePaired:(BOOL)assumePaired
{
    NSArray<CBPeripheral*> *peripherals = [_centralManager retrievePeripheralsWithIdentifiers:identifiers];
    
    NSMutableArray<RLYPeripheral*> *array = [NSMutableArray arrayWithCapacity:peripherals.count];
    
    for (CBPeripheral *peripheral in peripherals)
    {
        if (RLYCBPeripheralIsRingly(peripheral))
        {
            [array addObject:[RLYPeripheral peripheralForCBPeripheral:peripheral
                                                         assumePaired:assumePaired
                                                  centralManagerState:(CBCentralManagerState)_centralManager.state]];
        }
    }
    
    return array;
}

#pragma mark - Discovery
-(void)startDiscoveringPeripherals
{
    NSDictionary *options = @{ CBCentralManagerScanOptionAllowDuplicatesKey: @NO };
    [_centralManager scanForPeripheralsWithServices:nil options:options];

    self.discovery = [[RLYCentralDiscovery alloc] initWithPeripherals:@[]
                                                  recoveryPeripherals:@[]
                                                            startDate:[NSDate date]];
}

-(void)stopDiscoveringPeripherals
{
    [_centralManager stopScan];
    
    self.discovery = nil;
}

#pragma mark - Central Manager Delegate - State
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // this needs to be done first - the visible state property on this class can trigger side-effects once the change
    // is observed. therefore, all peripherals should be ready to perform actions before setting it.
    [RLYPeripheral enumerateKnownPeripherals:^(RLYPeripheral * _Nonnull peripheral) {
        peripheral.centralManagerState = (CBCentralManagerState)central.state;
    }];
    
    self.managerState = (CBCentralManagerState)central.state;
    
    switch (central.state)
    {
        case CBCentralManagerStatePoweredOff:
        case CBCentralManagerStateResetting:
            if (self.discovery != nil)
            {
                [self stopDiscoveringPeripherals];
            }
            break;
        default:
            break;
    }
}

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
-(void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict
{
    RLYLogFunction(@"Central Manager Will Restore State %@", dict);
    
    NSArray<CBPeripheral*>* restored = dict[CBCentralManagerRestoredStatePeripheralsKey];
    NSMutableArray<RLYPeripheral*>* peripherals = [NSMutableArray arrayWithCapacity:restored.count];
    
    for (CBPeripheral *peripheral in restored)
    {
        // ensure that the peripheral is a ringly, and it supports the ringly service
        // without the services check, we could possibly get a recovery mode peripheral - which would be bad
        BOOL servicesMatch = RLYAny(peripheral.services, ^BOOL(CBService *service) {
            return [service.UUID isEqual:[RLYUUID ringlyServiceShort]] || [service.UUID isEqual:[RLYUUID ringlyServiceLong]];
        });
        
        if (servicesMatch)
        {
            RLYPeripheral *wrapper = [RLYPeripheral peripheralForCBPeripheral:peripheral
                                                                 assumePaired:YES
                                                          centralManagerState:(CBCentralManagerState)_centralManager.state];
            
            [peripherals addObject:wrapper];
        }
    }
    
    if (peripherals.count > 0)
    {
        [_observers enumerateObservers:^(id<RLYCentralObserver> observer) {
            if ([observer respondsToSelector:@selector(central:didRestorePeripherals:)])
            {
                [observer central:self didRestorePeripherals:peripherals];
            }
        }];
    }
}
#endif

#pragma mark - Central Manager Delegate - Discovering and Retrieving Peripherals
- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)discoveredPeripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    // make sure we haven't already found this exact peripheral object
    BOOL havePeripheral = RLYAny(_discovery.peripherals, ^BOOL(RLYPeripheral *peripheral) {
        return peripheral.CBPeripheral == discoveredPeripheral
            || [peripheral.CBPeripheral.identifier isEqual:discoveredPeripheral.identifier];
    });
    
    havePeripheral = havePeripheral || RLYAny(_discovery.recoveryPeripherals, ^BOOL(RLYRecoveryPeripheral *recovery) {
        return [recovery.peripheral isEqual:discoveredPeripheral];
    });
    
    if (!havePeripheral)
    {
        if (RLYCBPeripheralIsRingly(discoveredPeripheral))
        {
            if (RLYAdvertismentDataIsInRecoveryMode(advertisementData))
            {
                RLYRecoveryPeripheral *recovery = [[RLYRecoveryPeripheral alloc] initWithPeripheral:discoveredPeripheral
                                                                                  advertisementData:advertisementData];
                NSArray *recoveryPeripherals = [_discovery.recoveryPeripherals arrayByAddingObject:recovery];

                self.discovery = [[RLYCentralDiscovery alloc] initWithPeripherals:_discovery.peripherals
                                                              recoveryPeripherals:recoveryPeripherals
                                                                        startDate:_discovery.startDate];
            }
            else
            {
                RLYPeripheral *peripheral = [RLYPeripheral peripheralForCBPeripheral:discoveredPeripheral
                                                                        assumePaired:NO
                                                                 centralManagerState:(CBCentralManagerState)_centralManager.state];

                NSArray *peripherals = [_discovery.peripherals arrayByAddingObject:peripheral];

                self.discovery = [[RLYCentralDiscovery alloc] initWithPeripherals:peripherals
                                                              recoveryPeripherals:_discovery.recoveryPeripherals
                                                                        startDate:_discovery.startDate];
            }
        }
    }
}

#pragma mark - Central Manager Delegate - Connecting to Peripherals
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)CBPeripheral
{
    RLYPeripheral *peripheral = [RLYPeripheral peripheralForCBPeripheral:CBPeripheral
                                                            assumePaired:NO
                                                     centralManagerState:(CBCentralManagerState)_centralManager.state];
    
    if (peripheral)
    {
        // notify observers
        [_observers enumerateObservers:^(id<RLYCentralObserver> observer) {
            if ([observer respondsToSelector:@selector(central:didConnectToPeripheral:)])
            {
                [observer central:self didConnectToPeripheral:peripheral];
            }
        }];
    }
}

-(void)centralManager:(CBCentralManager*)central didFailToConnectPeripheral:(CBPeripheral*)CBPeripheral error:(NSError*)error
{
    RLYPeripheral *peripheral = [RLYPeripheral peripheralForCBPeripheral:CBPeripheral
                                                            assumePaired:NO
                                                     centralManagerState:(CBCentralManagerState)_centralManager.state];
    
    if (peripheral)
    {
        [_observers enumerateObservers:^(id<RLYCentralObserver> observer) {
            if ([observer respondsToSelector:@selector(central:didFailToConnectPeripheral:withError:)])
            {
                [observer central:self didFailToConnectPeripheral:peripheral withError:error];
            }
        }];
    }
}

#pragma mark - Central Manager Delegate - Disconnecting from Peripherals
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)CBPeripheral error:(NSError *)error
{
    RLYPeripheral *peripheral = [RLYPeripheral peripheralForCBPeripheral:CBPeripheral
                                                            assumePaired:NO
                                                     centralManagerState:(CBCentralManagerState)_centralManager.state];
    
    if (peripheral)
    {
        // When a peripheral disconnects, if it is currently verified to be paired, set it to non-verified. The user
        // can forget the peripheral while it is disconnected, and we won't be notified. Therefore, we should revert to
        // just assuming that it is paired. Once it reconnects, its pair state can be read again.
        if (peripheral.paired)
        {
            peripheral.pairState = RLYPeripheralPairStateAssumedPaired;
        }
        
        // notify observers of the change
        [_observers enumerateObservers:^(id<RLYCentralObserver> observer) {
            if ([observer respondsToSelector:@selector(central:didDisconnectFromPeripheral:withError:)])
            {
                [observer central:self didDisconnectFromPeripheral:peripheral withError:error];
            }
        }];
        
        // if we do not receive an error, this means that the user tapped "forget this device" in settings.
        if (!error)
        {
            [_observers enumerateObservers:^(id<RLYCentralObserver> observer) {
                if ([observer respondsToSelector:@selector(central:userDidForgetPeripheral:)])
                {
                    [observer central:self userDidForgetPeripheral:peripheral];
                }
            }];
        }
    }
}

@end
