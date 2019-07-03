#import <TargetConditionals.h>
#import "RLYANCSV1Parser.h"
#import "RLYANCSV2Parser.h"
#import "RLYActivityTrackingUpdate+Internal.h"
#import "RLYClearBondsCommand.h"
#import "RLYCommand+Internal.h"
#import "RLYDateTimeCommand.h"
#import "RLYDefines+Internal.h"
#import "RLYErrorFunctions.h"
#import "RLYFunctions.h"
#import "RLYColorVibrationCommand.h"
#import "RLYLogFunction.h"
#import "RLYObservers.h"
#import "RLYPeripheral.h"
#import "RLYPeripheral+Internal.h"
#import "RLYPeripheralActivityCharacteristics.h"
#import "RLYPeripheralBatteryCharacteristics.h"
#import "RLYPeripheralDeviceInformationCharacteristics.h"
#import "RLYPeripheralLoggingCharacteristics.h"
#import "RLYPeripheralRinglyCharacteristics.h"
#import "RLYPeripheralEnumerations+Internal.h"
#import "RLYPeripheralServices.h"
#import "RLYUUID.h"

@interface RLYPeripheral () <RLYANCSV1ParserDelegate, CBPeripheralDelegate>
{
@private
    // observers
    RLYObservers *_observers;
    
    // ANCS
    RLYANCSV1Parser *_ANCSParser;
    
    // configuration hash completion blocks
    NSMutableArray *_configurationHashBlocks;
}

// ANCS v2
@property (nonatomic) NSUInteger lastNotificationAttributeCount;
@property (nonatomic) NSUInteger lastApplicationAttributeCount;

// readiness
@property (nullable, nonatomic, strong) NSArray<NSError*> *validationErrors;

// services
@property (nullable, nonatomic, strong) RLYPeripheralServices *peripheralServices;

// characteristics
@property (nullable, nonatomic, strong) RLYPeripheralRinglyCharacteristics *ringlyCharacteristics;
@property (nullable, nonatomic, strong) RLYPeripheralDeviceInformationCharacteristics *deviceInformationCharacteristics;
@property (nullable, nonatomic, strong) RLYPeripheralBatteryCharacteristics *batteryCharacteristics;
@property (nullable, nonatomic, strong) RLYPeripheralLoggingCharacteristics *loggingCharacteristics;
@property (nullable, nonatomic, strong) RLYPeripheralActivityCharacteristics *activityCharacteristics;

@property (nonnull, nonatomic, strong) NSSet<CBCharacteristic*> *characteristicsWaitingForBond;
@property (nonnull, nonatomic, strong) NSSet<CBCharacteristic*> *characteristicsWaitingForNotificationCallback;

// state
@property (nonatomic) CBPeripheralState state;
@property (nonatomic) RLYPeripheralShutdownReason lastShutdownReason;

// battery
@property (nonatomic) BOOL batteryStateDetermined;
@property (nonatomic) RLYPeripheralBatteryState batteryState;
@property (nonatomic) BOOL batteryChargeDetermined;
@property (nonatomic) NSInteger batteryCharge;

// ring information
@property (nonatomic, strong) NSUUID *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *MACAddress;
@property (nonatomic, strong) NSString *applicationVersion;
@property (nonatomic, strong) NSString *hardwareVersion;
@property (nonatomic, strong) NSString *chipVersion;
@property (nonatomic, strong) NSString *bootloaderVersion;
@property (nonatomic, strong) NSString *softdeviceVersion;

// activity tracking
@property (nonatomic, getter=isSubscribedToActivityNotifications) BOOL subscribedToActivityNotifications;

// keyframe state
@property (nonatomic, assign) RLYPeripheralFramesState framesState;

@end

#define PERIPHERAL_SET_ERROR_AND_RETURN_NO(errorCode) \
    do { \
        if (error) { *error = RLYPeripheralError(errorCode); } \
        return NO;\
    } while(NO)

static uint8_t RLYPeripheralKVOContext;

@implementation RLYPeripheral

_RLY_OBSERVABLE_BOILERPLATE(RLYPeripheralObserver, _observers)

static NSMapTable *RLYPeripheralUniqueTable = nil;

#pragma mark - Unique
+(nullable instancetype)peripheralForCBPeripheral:(nonnull CBPeripheral *)CBPeripheral
                                     assumePaired:(BOOL)assumePaired
                              centralManagerState:(CBCentralManagerState)centralManagerState
{
    if (RLYCBPeripheralIsRingly(CBPeripheral))
    {
        RLYPeripheral *peripheral = [RLYPeripheralUniqueTable objectForKey:CBPeripheral];
        
        if (!peripheral)
        {
            if (!RLYPeripheralUniqueTable)
            {
                RLYPeripheralUniqueTable = [NSMapTable weakToWeakObjectsMapTable];
            }
            
            peripheral = [[self alloc] initWithCBPeripheral:CBPeripheral];
            peripheral.centralManagerState = centralManagerState;
            [RLYPeripheralUniqueTable setObject:peripheral forKey:CBPeripheral];
        }
        
        if (!peripheral.paired && assumePaired)
        {
            peripheral.pairState = RLYPeripheralPairStateAssumedPaired;
        }
        
        return peripheral;
    }
    else
    {
        return nil;
    }
}

+(void)enumerateKnownPeripherals:(void(^)(RLYPeripheral *peripheral))block
{
    for (RLYPeripheral *peripheral in RLYPeripheralUniqueTable.objectEnumerator)
    {
        block(peripheral);
    }
}

-(void)dealloc
{
    _CBPeripheral.delegate = nil;
    [_CBPeripheral removeObserver:self forKeyPath:RLY_KEYPATH(self, state)];
    
    [RLYPeripheralUniqueTable removeObjectForKey:_CBPeripheral];
    
    if (RLYPeripheralUniqueTable.count == 0)
    {
        RLYPeripheralUniqueTable = nil;
    }
}

#pragma mark - Initialization
-(instancetype)initWithCBPeripheral:(CBPeripheral*)CBPeripheral
{
    self = [super init];
    
    if (self)
    {
        _observers = [RLYObservers new];

        _configurationHashBlocks = [NSMutableArray array];
        
        _CBPeripheral = CBPeripheral;
        _CBPeripheral.delegate = self;
        
        _name = _CBPeripheral.name;
        _identifier = _CBPeripheral.identifier;
        
        _ANCSParser = [RLYANCSV1Parser new];
        _ANCSParser.delegate = self;
        
        _characteristicsWaitingForNotificationCallback = [NSSet set];
        _characteristicsWaitingForBond = [NSSet set];
        
        [_CBPeripheral addObserver:self
                        forKeyPath:RLY_KEYPATH(_CBPeripheral, state)
                           options:0
                           context:&RLYPeripheralKVOContext];
        
        self.state = CBPeripheral.state;
    }
    
    return self;
}

#pragma mark - Debug
-(NSString*)description
{
    return [NSString stringWithFormat:@"%@ (%@)", [super description], _CBPeripheral];
}

#pragma mark - Invalidating Properties

/// Resets the peripheral's device information properties, described in `RLYPeripheralDeviceInformation`.
-(void)invalidateDeviceInformation
{
    self.MACAddress = nil;
    self.applicationVersion = nil;
    self.bootloaderVersion = nil;
    self.softdeviceVersion = nil;
    self.hardwareVersion = nil;
    self.chipVersion = nil;
}

#pragma mark - Validation
+(NSSet*)keyPathsForValuesAffectingValidationState
{
    return [NSSet setWithObjects:
            RLY_CLASS_KEYPATH(RLYPeripheral, peripheralServices),
            RLY_CLASS_KEYPATH(RLYPeripheral, ringlyCharacteristics),
            RLY_CLASS_KEYPATH(RLYPeripheral, deviceInformationCharacteristics),
            RLY_CLASS_KEYPATH(RLYPeripheral, batteryCharacteristics),
            RLY_CLASS_KEYPATH(RLYPeripheral, characteristicsWaitingForNotificationCallback),
            RLY_CLASS_KEYPATH(RLYPeripheral, characteristicsWaitingForBond),
            RLY_CLASS_KEYPATH(RLYPeripheral, validationErrors),
            nil];
}

-(RLYPeripheralValidationState)validationState
{
    if (!_peripheralServices)
    {
        return RLYPeripheralValidationStateMissingServices;
    }

    if (!_ringlyCharacteristics)
    {
        return RLYPeripheralValidationStateMissingRinglyCharacteristics;
    }

    if (!_deviceInformationCharacteristics)
    {
        return RLYPeripheralValidationStateMissingDeviceInformationCharacteristics;
    }

    if (!_batteryCharacteristics)
    {
        return RLYPeripheralValidationStateMissingBatteryCharacteristics;
    }

    if (_peripheralServices.activityService && !_activityCharacteristics)
    {
        return RLYPeripheralValidationStateMissingActivityTrackingCharacteristics;
    }

    if (_characteristicsWaitingForNotificationCallback.count + _characteristicsWaitingForBond.count != 0)
    {
        return RLYPeripheralValidationStateWaitingForNotificationStateConformation;
    }

    if (_validationErrors.count != 0)
    {
        return RLYPeripheralValidationStateHasValidationErrors;
    }

    return RLYPeripheralValidationStateValidated;
}

+(NSSet*)keyPathsForValuesAffectingValidated
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYPeripheral, validationState)];
}

-(BOOL)isValidated
{
    return self.validationState == RLYPeripheralValidationStateValidated;
}

-(void)addValidationError:(NSError*)error
{
    self.validationErrors = [(self.validationErrors ?: @[]) arrayByAddingObject:error];
}

#pragma mark - Notification Mode
+(NSSet*)keyPathsForValuesAffectingANCSNotificationMode
{
    return [NSSet setWithObjects:
            RLY_CLASS_KEYPATH(RLYPeripheral, ringlyCharacteristics.ANCSVersion1),
            RLY_CLASS_KEYPATH(RLYPeripheral, ringlyCharacteristics.ANCSVersion2),
            nil];
}

-(RLYPeripheralANCSNotificationMode)ANCSNotificationMode
{
    if (self.ringlyCharacteristics.ANCSVersion2)
    {
        return RLYPeripheralANCSNotificationModeAutomatic;
    }
    else if (self.ringlyCharacteristics.ANCSVersion1)
    {
        return RLYPeripheralANCSNotificationModePhone;
    }
    else
    {
        return RLYPeripheralANCSNotificationModeUnknown;
    }
}

#pragma mark - Connection State
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &RLYPeripheralKVOContext)
    {
        if (object == _CBPeripheral && [keyPath isEqualToString:RLY_KEYPATH(_CBPeripheral, state)])
        {
            self.state = _CBPeripheral.state;
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)setState:(CBPeripheralState)state
{
    _state = state;
    
    switch (_state)
    {
        case CBPeripheralStateConnected:
            if (_CBPeripheral.services.count == 0)
            {
                RLYBreakpointIf(_centralManagerState != CBCentralManagerStatePoweredOn);
                [_CBPeripheral discoverServices:[RLYUUID allServiceUUIDs]];
            }
            else if (!_peripheralServices)
            {
                [self mapServicesToIvars];
            }
            
            if (_lastShutdownReason != RLYPeripheralShutdownReasonNone)
            {
                self.lastShutdownReason = RLYPeripheralShutdownReasonNone;
            }
            
            break;
            
        case CBPeripheralStateDisconnected: {
            [self clearServicesAndCharacteristics];

            // reset properties that are now unknowable
            self.batteryChargeDetermined = NO;
            self.batteryStateDetermined = NO;
            self.subscribedToActivityNotifications = NO;
            
            break;
        }
    
        case CBPeripheralStateConnecting:
            break;
            
#if TARGET_OS_IPHONE
        case CBPeripheralStateDisconnecting:
            break;
#endif
    }
}

-(void)clearServicesAndCharacteristics
{
    // remove characteristic representations
    self.ringlyCharacteristics = nil;
    self.deviceInformationCharacteristics = nil;
    self.batteryCharacteristics = nil;
    self.loggingCharacteristics = nil;
    self.characteristicsWaitingForNotificationCallback = [NSSet set];
    self.characteristicsWaitingForBond = [NSSet set];
    self.validationErrors = [NSArray array];

    // remove services representation
    self.peripheralServices = nil;
}

+(NSSet*)keyPathsForValuesAffectingDisconnected
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYPeripheral, state)];
}

-(BOOL)isDisconnected
{
    return _state == CBPeripheralStateDisconnected;
}

+(NSSet*)keyPathsForValuesAffectingConnecting
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYPeripheral, state)];
}

-(BOOL)isConnecting
{
    return _state == CBPeripheralStateConnecting;
}

+(NSSet*)keyPathsForValuesAffectingConnected
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYPeripheral, state)];
}

-(BOOL)isConnected
{
    return _state == CBPeripheralStateConnected;
}

-(BOOL)isWaitingForCharacteristics
{
    return _characteristicsWaitingForNotificationCallback.count > 0;
}

-(void)setPairState:(RLYPeripheralPairState)pairState
{
    _pairState = pairState;

    if (RLYPeripheralPairStateIsPaired(_pairState))
    {
        for (CBCharacteristic *characteristic in _characteristicsWaitingForBond)
        {
            [self registerCharacteristicForNotifications:characteristic];
        }

        self.characteristicsWaitingForBond = [NSSet set];
    }
}

+(NSSet*)keyPathsForValuesAffectingPaired
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYPeripheral, pairState)];
}

-(BOOL)isPaired
{
    return RLYPeripheralPairStateIsPaired(_pairState);
}

#pragma mark - Battery
+(NSSet*)keyPathsForValuesAffectingCharging
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYPeripheral, batteryState)];
}

-(BOOL)isCharging
{
    return _batteryState == RLYPeripheralBatteryStateCharging;
}

+(NSSet*)keyPathsForValuesAffectingChargingOrCharged
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYPeripheral, batteryState)];
}

-(BOOL)isChargingOrCharged
{
    return _batteryState == RLYPeripheralBatteryStateCharging || _batteryState == RLYPeripheralBatteryStateCharged;
}

#pragma mark - Commands
-(void)writeCommand:(id<RLYCommand>)command
{
    RLYBreakpointIf(_centralManagerState != CBCentralManagerStatePoweredOn);
    
    [_observers enumerateObservers:^void(id<RLYPeripheralObserver> observer) {
        if ([observer respondsToSelector:@selector(peripheral:willWriteCommand:)])
        {
            [observer peripheral:self willWriteCommand:command];
        }
    }];
    
    if (self.canWriteCommands)
    {
        [_CBPeripheral writeValue:RLYCommandDataRepresentation(command)
                forCharacteristic:_ringlyCharacteristics.command
                             type:CBCharacteristicWriteWithResponse];
        
        [_observers enumerateObservers:^void(id<RLYPeripheralObserver> observer) {
            if ([observer respondsToSelector:@selector(peripheral:didWriteCommand:)])
            {
                [observer peripheral:self didWriteCommand:command];
            }
        }];
    }
    else
    {
        NSError *error = RLYPeripheralError(RLYPeripheralErrorCodePeripheralDisconnected);
        
        [_observers enumerateObservers:^void(id<RLYPeripheralObserver> observer) {
            if ([observer respondsToSelector:@selector(peripheral:failedToWriteCommand:withError:)])
            {
                [observer peripheral:self failedToWriteCommand:command withError:error];
            }
        }];
    }
}

-(void)writeClearBond
{
    if (_ringlyCharacteristics.clearBond)
    {
        RLYBreakpointIf(_centralManagerState != CBCentralManagerStatePoweredOn);
        
        const uint8_t byte = 1;
        NSData *byteData = [NSData dataWithBytes:&byte length:sizeof(byte)];
        
        [_CBPeripheral writeValue:byteData
                forCharacteristic:_ringlyCharacteristics.clearBond
                             type:CBCharacteristicWriteWithResponse];
    }
    else
    {
        [self writeCommand:[RLYClearBondsCommand new]];
    }
}

+(NSSet*)keyPathsForValuesAffectingCanWriteCommands
{
    return [NSSet setWithObjects:
            RLY_CLASS_KEYPATH(RLYPeripheral, state),
            RLY_CLASS_KEYPATH(RLYPeripheral, ringlyCharacteristics.command),
            nil];
}

-(BOOL)canWriteCommands
{
    return _state == CBPeripheralStateConnected && _ringlyCharacteristics.command;
}

#pragma mark - Reading Information
+(NSSet*)keyPathsForValuesAffectingReadBondCharacteristicSupport
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYPeripheral, ringlyCharacteristics)];
}

-(RLYPeripheralFeatureSupport)readBondCharacteristicSupport
{
    if (_ringlyCharacteristics)
    {
        return _ringlyCharacteristics.bond
             ? RLYPeripheralFeatureSupportSupported
             : RLYPeripheralFeatureSupportUnsupported;
    }
    else
    {
        return RLYPeripheralFeatureSupportUndetermined;
    }
}

-(BOOL)readBondCharacteristic:(NSError * _Nullable __autoreleasing *)error
{
    if (_ringlyCharacteristics.bond)
    {
        RLYBreakpointIf(_centralManagerState != CBCentralManagerStatePoweredOn);
        
        [_CBPeripheral readValueForCharacteristic:_ringlyCharacteristics.bond];
        return YES;
    }
    else
    {
        PERIPHERAL_SET_ERROR_AND_RETURN_NO(RLYPeripheralErrorCodeBondCharacteristicNotFound);
    }
}

-(BOOL)readBatteryCharacteristics:(NSError * __nullable __autoreleasing * __nullable)error
{
    BOOL success = YES;
    
    if (_batteryCharacteristics.state)
    {
        RLYBreakpointIf(_centralManagerState != CBCentralManagerStatePoweredOn);
        [_CBPeripheral readValueForCharacteristic:_batteryCharacteristics.state];
    }
    else
    {
        success = NO;
        
        if (error)
        {
            *error = RLYPeripheralError(RLYPeripheralErrorCodeBatteryStateCharacteristicNotFound);
        }
    }
    
    if (_batteryCharacteristics.charge)
    {
        RLYBreakpointIf(_centralManagerState != CBCentralManagerStatePoweredOn);
        [_CBPeripheral readValueForCharacteristic:_batteryCharacteristics.charge];
    }
    else
    {
        success = NO;
        
        if (error)
        {
            *error = RLYPeripheralError(RLYPeripheralErrorCodeBatteryChargeCharacteristicNotFound);
        }
    }
    
    return success;
}

-(BOOL)readDeviceInformationCharacteristics:(NSError**)error
{
    BOOL success = YES;
    
    if (_deviceInformationCharacteristics.application)
    {
        RLYBreakpointIf(_centralManagerState != CBCentralManagerStatePoweredOn);
        [_CBPeripheral readValueForCharacteristic:_deviceInformationCharacteristics.application];
    }
    else
    {
        success = NO;
        
        if (error)
        {
            *error = RLYPeripheralError(RLYPeripheralErrorCodeDeviceApplicationCharacteristicNotFound);
        }
    }
    
    if (_deviceInformationCharacteristics.hardware)
    {
        RLYBreakpointIf(_centralManagerState != CBCentralManagerStatePoweredOn);
        [_CBPeripheral readValueForCharacteristic:_deviceInformationCharacteristics.hardware];
    }
    else
    {
        success = NO;
        
        if (error)
        {
            *error = RLYPeripheralError(RLYPeripheralErrorCodeDeviceHardwareCharacteristicNotFound);
        }
    }
    
    // this characteristic is allowed to be nil, since it's only supported on application version 1.4 and greated
    if (_deviceInformationCharacteristics.MACAddress)
    {
        RLYBreakpointIf(_centralManagerState != CBCentralManagerStatePoweredOn);
        [_CBPeripheral readValueForCharacteristic:_deviceInformationCharacteristics.MACAddress];
    }
    
    // this characteristic is allowed to be nil, since it's only supported on application version 1.4 and greater
    if (_deviceInformationCharacteristics.bootloader)
    {
        RLYBreakpointIf(_centralManagerState != CBCentralManagerStatePoweredOn);
        [_CBPeripheral readValueForCharacteristic:_deviceInformationCharacteristics.bootloader];
    }
    
    // this characteristic is allowed to be nil, since it's only supported on application version 2.0 and greater
    if (_deviceInformationCharacteristics.chip)
    {
        RLYBreakpointIf(_centralManagerState != CBCentralManagerStatePoweredOn);
        [_CBPeripheral readValueForCharacteristic:_deviceInformationCharacteristics.chip];
    }
    
    // this characteristic is allowed to be nil, since it's only supported on application version 2.0 and greater
    if (_deviceInformationCharacteristics.softdevice)
    {
        RLYBreakpointIf(_centralManagerState != CBCentralManagerStatePoweredOn);
        [_CBPeripheral readValueForCharacteristic:_deviceInformationCharacteristics.softdevice];
    }
    
    return success;
}

#pragma mark - Configuration Hash
-(BOOL)writeConfigurationHash:(uint64_t)hash error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    if (_ringlyCharacteristics.configurationHash)
    {
        NSData *data = [NSData dataWithBytes:&hash length:sizeof(hash)];
        
        RLYBreakpointIf(_centralManagerState != CBCentralManagerStatePoweredOn);
        [_CBPeripheral writeValue:data
                forCharacteristic:_ringlyCharacteristics.configurationHash
                             type:CBCharacteristicWriteWithResponse];
        
        return YES;
    }
    else
    {
        PERIPHERAL_SET_ERROR_AND_RETURN_NO(RLYPeripheralErrorCodeConfigurationHashCharacteristicNotFound);
    }
}

-(void)readConfigurationHashWithCompletion:(void(^)(uint64_t hash))completion failure:(void(^)(NSError *error))failure
{
    if (_ringlyCharacteristics.configurationHash)
    {
        [_configurationHashBlocks addObject:@[[completion copy], [failure copy]]];
        
        if (_configurationHashBlocks.count == 1)
        {
            RLYBreakpointIf(_centralManagerState != CBCentralManagerStatePoweredOn);
            [_CBPeripheral readValueForCharacteristic:_ringlyCharacteristics.configurationHash];
        }
    }
    else
    {
        failure(RLYPeripheralError(RLYPeripheralErrorCodeConfigurationHashCharacteristicNotFound));
    }
}

#pragma mark - Activity Tracking
+(NSSet*)keypathsForValuesAffectingActivityTrackingSupport
{
    return [NSSet setWithObjects:RLY_CLASS_KEYPATH(RLYPeripheral, peripheralServices),
                                 RLY_CLASS_KEYPATH(RLYPeripheral, activityCharacteristics),
                                 nil];
}

-(RLYPeripheralFeatureSupport)activityTrackingSupport
{
    if (_peripheralServices)
    {
        if (_peripheralServices.activityService)
        {
            return _activityCharacteristics
                 ? RLYPeripheralFeatureSupportSupported
                 : RLYPeripheralFeatureSupportUndetermined;
        }
        else
        {
            return RLYPeripheralFeatureSupportUnsupported;
        }
    }
    else
    {
        return RLYPeripheralFeatureSupportUndetermined;
    }
}

-(BOOL)readActivityTrackingDataSinceDate:(RLYActivityTrackingDate*)date error:(NSError *_Nullable __autoreleasing*)error
{
    // check preconditions
    if (!_activityCharacteristics.controlPoint)
    {
        PERIPHERAL_SET_ERROR_AND_RETURN_NO(RLYPeripheralErrorCodeActivityControlPointCharacteristicNotFound);
    }

    if (!_subscribedToActivityNotifications)
    {
        PERIPHERAL_SET_ERROR_AND_RETURN_NO(RLYPeripheralErrorCodeNotSubscribedToActivityNotifications);
    }

    // write to the control point
    RLYActivityTrackingMinuteBytes intervalBytes =
        RLYActivityTrackingMinuteBytesFromMinute(date.minute);

    uint8_t bytes[6] = { 0, 0, 3, intervalBytes.first, intervalBytes.second, intervalBytes.third };
    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];

    [_CBPeripheral writeValue:data
            forCharacteristic:_activityCharacteristics.controlPoint
                         type:CBCharacteristicWriteWithResponse];

    return YES;
}

-(BOOL)updateActivityTrackingWithEnabled:(BOOL)enabled
                             sensitivity:(RLYActivityTrackingSensitivity)sensitivity
                                    mode:(RLYActivityTrackingMode)mode
                    minimumPeakIntensity:(RLYActivityTrackingPeakIntensity)minimumPeakIntensity
                       minimumPeakHeight:(RLYActivityTrackingPeakHeight)minimumPeakHeight
                                   error:(NSError * _Nullable __autoreleasing *)error
{
    // check precondition
    if (!_activityCharacteristics.controlPoint)
    {
        PERIPHERAL_SET_ERROR_AND_RETURN_NO(RLYPeripheralErrorCodeActivityControlPointCharacteristicNotFound);
    }

    // ensure endianness of intensity and height parameters
    uint16_t intensityLittle = CFSwapInt16HostToLittle(minimumPeakIntensity);
    uint16_t heightLittle = CFSwapInt16HostToLittle(minimumPeakHeight);

    // write settings to the control point
    uint8_t bytes[10] = {
        1,
        0,
        7,
        enabled ? 4 : 0,
        sensitivity,
        mode,
        ((uint8_t*)&intensityLittle)[0],
        ((uint8_t*)&intensityLittle)[1],
        ((uint8_t*)&heightLittle)[0],
        ((uint8_t*)&heightLittle)[1]
    };

    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];

    [_CBPeripheral writeValue:data
            forCharacteristic:_activityCharacteristics.controlPoint
                         type:CBCharacteristicWriteWithResponse];

    return YES;
}

#pragma mark - Flash Logging
-(BOOL)readFlashLogOfLength:(uint16_t)length atAddress:(uint32_t)address error:(NSError *__autoreleasing *)error
{
    if (!_loggingCharacteristics)
    {
        PERIPHERAL_SET_ERROR_AND_RETURN_NO(RLYPeripheralErrorCodeLoggingServiceNotFound);
    }

    if (!_loggingCharacteristics.request)
    {
        PERIPHERAL_SET_ERROR_AND_RETURN_NO(RLYPeripheralErrorCodeLoggingRequestCharacteristicNotFound);
    }

    [_CBPeripheral writeValue:RLYDataForReadingFlashLog(length, address)
            forCharacteristic:_loggingCharacteristics.request
                         type:CBCharacteristicWriteWithResponse];

    return YES;
}

#pragma mark - Ring Information
+(NSSet*)keyPathsForValuesAffectingShortName
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYPeripheral, name)];
}

-(NSString*)shortName
{
    return RLYPeripheralShortNameFromName(_name);
}

+(NSSet*)keyPathsForValuesAffectingStyle
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYPeripheral, shortName)];
}

-(RLYPeripheralStyle)style
{
    return RLYPeripheralStyleFromShortName(self.shortName);
}

+(NSSet*)keyPathsForValuesAffectingType
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYPeripheral, style)];
}

-(RLYPeripheralType)type
{
    return RLYPeripheralTypeFromStyle(self.style);
}

+(NSSet*)keyPathsForValuesAffectingBand
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYPeripheral, style)];
}

-(RLYPeripheralBand)band
{
    return RLYPeripheralBandFromStyle(self.style);
}

+(NSSet*)keyPathsForValuesAffectingStone
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYPeripheral, style)];
}

-(RLYPeripheralStone)stone
{
    return RLYPeripheralStoneFromStyle(self.style);
}

+(NSSet*)keyPathsForValuesAffectingLastFourMAC
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYPeripheral, name)];
}

-(NSString*)lastFourMAC
{
    NSString *string = [_name componentsSeparatedByString:@" "].lastObject;
    
    if (string.length == 6)
    {
        return [string substringWithRange:NSMakeRange(1, 4)];
    }
    else
    {
        return string;
    }
}

+(NSSet*)keyPathsForValuesAffectingMACAddressSupport
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYPeripheral, deviceInformationCharacteristics)];
}

-(RLYPeripheralFeatureSupport)MACAddressSupport
{
    if (_deviceInformationCharacteristics)
    {
        return _deviceInformationCharacteristics.MACAddress
             ? RLYPeripheralFeatureSupportSupported
             : RLYPeripheralFeatureSupportUnsupported;
    }
    else
    {
        return RLYPeripheralFeatureSupportUndetermined;
    }
}

+(NSSet*)keyPathsForValuesAffectingChipVersionSupport
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYPeripheral, deviceInformationCharacteristics)];
}

-(RLYPeripheralFeatureSupport)chipVersionSupport
{
    if (_deviceInformationCharacteristics)
    {
        return _deviceInformationCharacteristics.chip
             ? RLYPeripheralFeatureSupportSupported
             : RLYPeripheralFeatureSupportUnsupported;
    }
    else
    {
        return RLYPeripheralFeatureSupportUndetermined;
    }
}

+(NSSet*)keyPathsForValuesAffectingBootloaderVersionSupport
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYPeripheral, deviceInformationCharacteristics)];
}

-(RLYPeripheralFeatureSupport)bootloaderVersionSupport
{
    if (_deviceInformationCharacteristics)
    {
        return _deviceInformationCharacteristics.bootloader
             ? RLYPeripheralFeatureSupportSupported
             : RLYPeripheralFeatureSupportUnsupported;
    }
    else
    {
        return RLYPeripheralFeatureSupportUndetermined;
    }
}

+(NSSet*)keyPathsForValuesAffectingSoftdeviceVersionSupport
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYPeripheral, deviceInformationCharacteristics)];
}

-(RLYPeripheralFeatureSupport)softdeviceVersionSupport
{
    if (_deviceInformationCharacteristics)
    {
        return _deviceInformationCharacteristics.softdevice
             ? RLYPeripheralFeatureSupportSupported
             : RLYPeripheralFeatureSupportUnsupported;
    }
    else
    {
        return RLYPeripheralFeatureSupportUndetermined;
    }
}

#pragma mark - Known Hardware Versions
+(NSSet *)keyPathsForValuesAffectingKnownHardwareVersion
{
    return [NSSet setWithObject:RLY_CLASS_KEYPATH(RLYPeripheral, applicationVersion)];
}

-(nullable RLYKnownHardwareVersionValue *)knownHardwareVersion
{
    if (_applicationVersion)
    {
        NSArray<NSString*> *components = [_applicationVersion componentsSeparatedByString:@"."];

        if (components.count > 0)
        {
            if ([components[0] isEqualToString:@"1"])
            {
                return [[RLYKnownHardwareVersionValue alloc] initWithValue:RLYKnownHardwareVersion1];
            }
            else if ([components[0] isEqualToString:@"2"])
            {
                return [[RLYKnownHardwareVersionValue alloc] initWithValue:RLYKnownHardwareVersion2];
            }
        }
    }

    return nil;
}

#pragma mark - Mapping Services & Characteristics
-(void)mapServicesToIvars
{
    NSError *error = nil;
    RLYPeripheralServices *services = [RLYPeripheralServices peripheralServicesWithServices:_CBPeripheral.services
                                                                                      error:&error];
    
    if (services)
    {
        self.peripheralServices = services;
        
        // discover or map characteristics for all services
        for (CBService *service in _CBPeripheral.services)
        {
            if (service.characteristics.count > 0)
            {
                [self mapCharacteristicsOfServiceToIvars:service];
            }
            else
            {
                RLYBreakpointIf(_centralManagerState != CBCentralManagerStatePoweredOn);
                [_CBPeripheral discoverCharacteristics:nil forService:service];
            }
        }
    }
    else
    {
        [self addValidationError:error];
    }
}

-(void)mapCharacteristicsOfServiceToIvars:(CBService*)service
{
    if (service == _peripheralServices.ringlyService)
    {
        NSError *error = nil;
        RLYPeripheralRinglyCharacteristics *characteristics =
            [RLYPeripheralRinglyCharacteristics peripheralCharacteristicsWithCharacteristics:service.characteristics
                                                                                       error:&error];
        
        if (characteristics)
        {
            [self registerCharacteristicForNotifications:characteristics.message];

            if (characteristics.ANCSVersion1)
            {
                [self registerCharacteristicForNotifications:characteristics.ANCSVersion1];
            }
            else if (characteristics.ANCSVersion2)
            {
                [self registerCharacteristicForNotifications:characteristics.ANCSVersion2];
            }

            if (characteristics.bond && RLYSupportsNotifyOrIndicate(characteristics.bond.properties))
            {
                [self registerCharacteristicForNotifications:characteristics.bond];
            }

            self.ringlyCharacteristics = characteristics;
        }
        else if (error)
        {
            [self addValidationError:error];
        }
    }
    else if (service == _peripheralServices.batteryService)
    {
        NSError *error = nil;
        RLYPeripheralBatteryCharacteristics *characteristics =
            [RLYPeripheralBatteryCharacteristics peripheralCharacteristicsWithCharacteristics:service.characteristics
                                                                                        error:&error];
        
        if (characteristics)
        {
            [self registerCharacteristicForNotifications:characteristics.charge];
            [self registerCharacteristicForNotifications:characteristics.state];

            self.batteryCharacteristics = characteristics;
        }
        else if (error)
        {
            [self addValidationError:error];
        }
    }
    else if (service == _peripheralServices.deviceInformationService)
    {
        NSError *error = nil;
        RLYPeripheralDeviceInformationCharacteristics *characteristics =
            [RLYPeripheralDeviceInformationCharacteristics
                peripheralCharacteristicsWithCharacteristics:service.characteristics error:&error];
        
        if (characteristics)
        {
            self.deviceInformationCharacteristics = characteristics;
        }
        else if (error)
        {
            [self addValidationError:error];
        }
    }
    else if (service == _peripheralServices.loggingService)
    {
        NSError *error = nil;
        RLYPeripheralLoggingCharacteristics *characteristics =
            [RLYPeripheralLoggingCharacteristics peripheralCharacteristicsWithCharacteristics:service.characteristics
                                                                                        error:&error];
        
        if (characteristics)
        {
            if (characteristics.flash && RLYSupportsNotifyOrIndicate(characteristics.flash.properties))
            {
                [self registerCharacteristicForNotifications:characteristics.flash];
            }

            self.loggingCharacteristics = characteristics;
        }
        else
        {
            RLYLogFunction(@"Error mapping logging characteristics on “%@”: %@", self.lastFourMAC, error);
        }
    }
    else if (service == _peripheralServices.activityService)
    {
        NSError *error = nil;
        RLYPeripheralActivityCharacteristics *characteristics =
            [RLYPeripheralActivityCharacteristics peripheralCharacteristicsWithCharacteristics:service.characteristics
                                                                                         error:&error];

        if (characteristics)
        {
            [self registerCharacteristicForNotifications:characteristics.trackingData];
            self.activityCharacteristics = characteristics;
        }
        else
        {
            RLYLogFunction(@"Error mapping activity characteristics on “%@”: %@", self.lastFourMAC, error);
        }
    }
}

#pragma mark - Notifications & Indications
-(void)registerCharacteristicForNotifications:(CBCharacteristic*)characteristic
{
    if (![_characteristicsWaitingForNotificationCallback containsObject:characteristic] &&
        ![_characteristicsWaitingForBond containsObject:characteristic])
    {
        if (RLYRequiresEncryptionForNotifyOrIndicate(characteristic.properties) && !self.isPaired)
        {
            RLYLogFunction(@"Waiting for bond to register for notification from “%@” on “%@”",
                           [RLYPeripheral UUIDDescriptionForCharacteristicWithUUID:characteristic.UUID],
                           self.lastFourMAC);

            // await bond before registering for this characteristics
            self.characteristicsWaitingForBond = [_characteristicsWaitingForBond setByAddingObject:characteristic];
        }
        else
        {
            RLYLogFunction(@"Registering for notifications from “%@” on “%@”",
                           [RLYPeripheral UUIDDescriptionForCharacteristicWithUUID:characteristic.UUID],
                           self.lastFourMAC);

            // await this characteristic updating
            self.characteristicsWaitingForNotificationCallback =
                [_characteristicsWaitingForNotificationCallback setByAddingObject:characteristic];

            // start updating
            [_CBPeripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
    else
    {
        RLYLogFunction(@"Already waiting for “%@” on “%@”",
                       [RLYPeripheral UUIDDescriptionForCharacteristicWithUUID:characteristic.UUID],
                       self.lastFourMAC);
    }
}

#pragma mark - Messages
-(void)handleMessageWithData:(NSData*)data
{
    // read the message type as the first byte of the message
    uint8_t *valueBytes = (uint8_t*)data.bytes;
    RLYPeripheralMessageType type = (RLYPeripheralMessageType)valueBytes[0];
    
    // separate out the remainder of the message, and declare a pointer to the bytes
    NSData *message = [data subdataWithRange:NSMakeRange(1, data.length - 1)];
    uint8_t *messageBytes = (uint8_t*)message.bytes;
    
    switch (type)
    {
        // events
        case RLYPeripheralMessageTypeTap: {
            // we require a string of at least 1 byte length, plus a byte for the leading comma separator
            if (message.length >= 2)
            {
                // strip the comma header
                NSData *ASCIIData = [message subdataWithRange:NSMakeRange(1, message.length - 1)];
                
                // parse the remainder as a string, then convert to an integer value
                NSInteger count = [NSString stringWithUTF8String:ASCIIData.bytes].integerValue;
                
                [_observers enumerateObservers:^void(id<RLYPeripheralObserver> observer) {
                    if ([observer respondsToSelector:@selector(peripheral:receivedTapsWithCount:)])
                    {
                        [observer peripheral:self receivedTapsWithCount:(NSUInteger)count];
                    }
                }];
            }
            
            break;
        }
            
        case RLYPeripheralMessageTypeTimerTrigger:
            break;
            
        // ANCS
        case RLYPeripheralMessageTypeNewANCSV2:
            // we require a byte for each attribute count
            if (message.length >= 2)
            {
                self.lastNotificationAttributeCount = messageBytes[0];
                self.lastApplicationAttributeCount = messageBytes[1];
                
                RLYBreakpointIf(_centralManagerState != CBCentralManagerStatePoweredOn);
                [_CBPeripheral readValueForCharacteristic:_ringlyCharacteristics.ANCSVersion2];
            }
            break;
            
        // setting confirmations
        case RLYPeripheralMessageTypeApplicationSettingConfirmation:
            if (message.length >= 13)
            {
                RLYParseConfirmationMessage(message, ^{
                    // parse app identifier fragment
                    NSData *fragmentData = [message subdataWithRange:NSMakeRange(0, 13)];
                    NSString *fragment = RLYFindValidUTF8Prefix(RLYSubdataToFirstNull(fragmentData));
                    
                    if (message.length == 17)
                    {
                        // parse color and vibration information from the end of the message
                        RLYColor color = RLYColorMake(messageBytes[13],
                                                      messageBytes[14],
                                                      messageBytes[15]);
                        
                        RLYVibration vibration = RLYVibrationFromCount(messageBytes[16]);
                        
                        [_observers enumerateObservers:^(id<RLYPeripheralObserver> observer) {
                            if ([observer respondsToSelector:@selector(peripheral:confirmedApplicationSettingWithFragment:color:vibration:)])
                            {
                                [observer peripheral:self confirmedApplicationSettingWithFragment:fragment
                                               color:color
                                           vibration:vibration];
                            }
                        }];
                    }
                    else
                    {
                        [_observers enumerateObservers:^(id<RLYPeripheralObserver> observer) {
                            if ([observer respondsToSelector:@selector(peripheral:failedApplicationSettingWithFragment:)])
                            {
                                [observer peripheral:self failedApplicationSettingWithFragment:fragment];
                            }
                        }];
                    }
                }, ^{ // deleted
                    [_observers enumerateObservers:^(id<RLYPeripheralObserver> observer) {
                        if ([observer respondsToSelector:@selector(peripheralConfirmedApplicationSettingDeleted:)])
                        {
                            [observer peripheralConfirmedApplicationSettingDeleted:self];
                        }
                    }];
                }, ^{ // cleared
                    [_observers enumerateObservers:^(id<RLYPeripheralObserver> observer) {
                        if ([observer respondsToSelector:@selector(peripheralConfirmedApplicationSettingsCleared:)])
                        {
                            [observer peripheralConfirmedApplicationSettingsCleared:self];
                        }
                    }];
                });
            }
            
            break;
            
        case RLYPeripheralMessageTypeContactSettingConfirmation:
            if (message.length >= 14)
            {
                RLYParseConfirmationMessage(message, ^{
                    // parse contact name fragment
                    NSData *fragmentData = [message subdataWithRange:NSMakeRange(0, 14)];
                    NSString *fragment = RLYFindValidUTF8Prefix(RLYSubdataToFirstNull(fragmentData));
                    
                    if (message.length == 17)
                    {
                        // parse color information from the end of the message
                        RLYColor color = RLYColorMake(messageBytes[14],
                                                      messageBytes[15],
                                                      messageBytes[16]);
                        
                        [_observers enumerateObservers:^(id<RLYPeripheralObserver> observer) {
                            if ([observer respondsToSelector:@selector(peripheral:confirmedContactSettingWithFragment:color:)])
                            {
                                [observer peripheral:self confirmedContactSettingWithFragment:fragment
                                               color:color];
                            }
                        }];
                    }
                    else
                    {
                        [_observers enumerateObservers:^(id<RLYPeripheralObserver> observer) {
                            if ([observer respondsToSelector:@selector(peripheral:failedContactSettingWithFragment:)])
                            {
                                [observer peripheral:self failedContactSettingWithFragment:fragment];
                            }
                        }];
                    }
                }, ^{ // deleted
                    [_observers enumerateObservers:^(id<RLYPeripheralObserver> observer) {
                        if ([observer respondsToSelector:@selector(peripheralConfirmedContactSettingDeleted:)])
                        {
                            [observer peripheralConfirmedContactSettingDeleted:self];
                        }
                    }];
                }, ^{ // cleared
                    [_observers enumerateObservers:^(id<RLYPeripheralObserver> observer) {
                        if ([observer respondsToSelector:@selector(peripheralConfirmedContactSettingsCleared:)])
                        {
                            [observer peripheralConfirmedContactSettingsCleared:self];
                        }
                    }];
                });
            }
            
            break;
            
        // bond information
        case RLYPeripheralMessageTypeBonded:
            if (self.pairState != RLYPeripheralPairStatePaired)
            {
                self.pairState = RLYPeripheralPairStatePaired;
            }
            
            break;
            
        case RLYPeripheralMessageTypeKeyframeCallback: {
            uint32_t status = CFSwapInt32LittleToHost(((uint32_t*)messageBytes)[0]);

            
            if(status == 2) {
                self.framesState = RLYPeripheralFramesStateEnded;
                self.framesState = RLYPeripheralFramesStateNotStarted;
            } else if(status == 1) {
                self.framesState = RLYPeripheralFramesStateStarted;
            } else  if(status == 0) {
                self.framesState = RLYPeripheralFramesStateNotStarted;
            }
            
            break;
        }
        case RLYPeripheralMessageTypeClearBondConfirmation:
            if (self.pairState != RLYPeripheralPairStateUnpaired)
            {
                self.pairState = RLYPeripheralPairStateUnpaired;
            }
            
            break;
            
        // shutdowns
        case RLYPeripheralMessageTypeLowBatteryShutdown: {
            self.lastShutdownReason = RLYPeripheralShutdownReasonBattery;
            
            [_observers enumerateObservers:^void(id<RLYPeripheralObserver> observer) {
                if ([observer respondsToSelector:@selector(peripheral:isShuttingDownWithReason:)])
                {
                    [observer peripheral:self isShuttingDownWithReason:RLYPeripheralShutdownReasonBattery];
                }
            }];
            
            break;
        }
            
        case RLYPeripheralMessageTypeSleepShutdown: {
            self.lastShutdownReason = RLYPeripheralShutdownReasonIdle;
            
            [_observers enumerateObservers:^void(id<RLYPeripheralObserver> observer) {
                if ([observer respondsToSelector:@selector(peripheral:isShuttingDownWithReason:)])
                {
                    [observer peripheral:self isShuttingDownWithReason:RLYPeripheralShutdownReasonIdle];
                }
            }];
            
            break;
        }
        
        // diagnostics
        case RLYPeripheralMessageTypeApplicationErrorReset: {
            // we need enough bytes for the line number - filename could be an empty string, technically
            if (message.length >= sizeof(uint32_t) * 2)
            {
                // extract the error code from the first two bytes of the message
                uint32_t errorCode = CFSwapInt32LittleToHost(((uint32_t*)messageBytes)[0]);
                
                // extract the line number from the second two bytes of the message
                uint32_t lineNumber = CFSwapInt32LittleToHost(((uint32_t*)messageBytes)[1]);
                
                // move past the error code and line number bytes to build the filename
                size_t offset = sizeof(errorCode) + sizeof(lineNumber);
                
                NSData *filenameData = [message subdataWithRange:NSMakeRange(offset, message.length - offset)];
                NSString *filename = RLYFindValidUTF8Prefix(RLYSubdataToFirstNull(filenameData));
                
                [_observers enumerateObservers:^(id<RLYPeripheralObserver> observer) {
                    if ([observer respondsToSelector:@selector(peripheral:encounteredApplicationErrorWithCode:lineNumber:filename:)])
                    {
                        [observer peripheral:self encounteredApplicationErrorWithCode:errorCode
                                  lineNumber:lineNumber
                                    filename:filename];
                    }
                }];
            }

            break;
        }
            
        case RLYPeripheralMessageTypeGPIOPinReport:
            break;
            
        default: {
            [_observers enumerateObservers:^void(id<RLYPeripheralObserver> observer) {
                if ([observer respondsToSelector:@selector(peripheral:receivedUnsupportedMessageType:withData:)])
                {
                    [observer peripheral:self receivedUnsupportedMessageType:type withData:message];
                }
            }];
            
            break;
        }
    }
}

#pragma mark - Peripheral Delegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    // if we didn't get an explicit error, but didn't find any services, consider than to be an error
    if (!error && peripheral.services.count == 0)
    {
        error = RLYPeripheralError(RLYPeripheralErrorCodeNoServicesFound);
    }

    RLYLogFunction(@"Discovered services on “%@”: %@", self.lastFourMAC, peripheral.services);
    
    if (error)
    {
        [self addValidationError:error];
    }
    else
    {
        [self mapServicesToIvars];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices
{
    RLYLogFunction(@"Peripheral “%@” modified services, rediscovering...", self.lastFourMAC);

    [self clearServicesAndCharacteristics];
    [peripheral discoverServices:[RLYUUID allServiceUUIDs]];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error;
{
    if (error)
    {
        [self addValidationError:error];
    }
    else
    {
        RLYLogFunction(@"Discovered characteristics of service %@ on “%@”: %@", service.UUID, self.lastFourMAC, service.characteristics);
        [self mapCharacteristicsOfServiceToIvars:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (characteristic == _ringlyCharacteristics.ANCSVersion1)
    {
        if (characteristic.value.bytes)
        {
            [_ANCSParser appendData:characteristic.value];
        }
        else
        {
            RLYLogFunction(@"Error appending ANCS version 1 data: %@", error);
        }
    }
    else if (characteristic == _ringlyCharacteristics.ANCSVersion2)
    {
        if (characteristic.value.bytes)
        {
            NSError *parseError = nil;
            RLYANCSNotification *notification = [RLYANCSV2Parser parseData:characteristic.value
                                            withNotificationAttributeCount:_lastNotificationAttributeCount
                                                 applicationAttributeCount:_lastApplicationAttributeCount
                                                                     error:&parseError];
            
            if (notification)
            {
                [_observers enumerateObservers:^void(id<RLYPeripheralObserver> __nonnull observer) {
                    if ([observer respondsToSelector:@selector(peripheral:didReceiveANCSNotification:)])
                    {
                        [observer peripheral:self didReceiveANCSNotification:notification];
                    }
                }];
            }
            else
            {
                RLYLogFunction(@"Error reading ANCS version 2 data from “%@”: %@", self.lastFourMAC, parseError);
            }
        }
        else
        {
            RLYLogFunction(@"Error reading ANCS version 2 data from “%@”: %@", self.lastFourMAC, error);
        }
    }
    else if (characteristic == _ringlyCharacteristics.message)
    {
        NSData *value = characteristic.value;
        
        if (value.bytes && value.length > 0)
        {
            [self handleMessageWithData:value];
        }
        else
        {
            RLYLogFunction(@"Error reading value of message characteristic: %@", error);
        }
    }
    else if (characteristic == _batteryCharacteristics.state)
    {
        if (characteristic.value.bytes)
        {
            unsigned char value;
            [characteristic.value getBytes:&value length:sizeof(value)];
            
            if (value >= 0 && value < 3)
            {
                self.batteryState = (RLYPeripheralBatteryState)value;
            }
            else
            {
                self.batteryState = RLYPeripheralBatteryStateError;
            }
            
            if (!_batteryStateDetermined)
            {
                self.batteryStateDetermined = YES;
            }
        }
        else
        {
            RLYLogFunction(@"Error reading value of battery state characteristic: %@", error);
        }
    }
    else if (characteristic == _batteryCharacteristics.charge)
    {
        if (characteristic.value.length > 0)
        {
            // read the battery state
            uint8_t value = ((uint8_t*)characteristic.value.bytes)[0];

            if (value == 0)
            {
                RLYLogFunction(@"Read 0 value for battery of “%@”", self.lastFourMAC);
            }
            
            if (_batteryState == RLYPeripheralBatteryStateCharged && value == 0)
            {
                self.batteryCharge = 100;
            }
            else if (value != 0) // ring incorrectly reports 0 shortly after startup, true 0 is obviously not possible
            {
                self.batteryCharge = (NSInteger)value;
            }
            
            if (!_batteryChargeDetermined)
            {
                self.batteryChargeDetermined = YES;
            }
        }
        else
        {
            RLYLogFunction(@"Error reading value of battery charge characteristic: %@", error);
        }
    }
    else if (characteristic == _deviceInformationCharacteristics.MACAddress)
    {
        if (characteristic.value.bytes)
        {
            self.MACAddress = [NSString stringWithUTF8String:characteristic.value.bytes];
        }
        else
        {
            RLYLogFunction(@"Error reading value of MAC address characteristic: %@", error);
        }
    }
    else if (characteristic == _deviceInformationCharacteristics.application)
    {
        if (characteristic.value.bytes)
        {
            self.applicationVersion = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
            
            // enable flags data parsing on versions above 1.4.3
            if (_applicationVersion && RLYCompareVersionNumbers(_applicationVersion, @"1.4.3") == NSOrderedDescending)
            {
                _ANCSParser.includeFlags = YES;
            }
        }
        else
        {
            RLYLogFunction(@"Error reading value of application version characteristic: %@", error);
        }
    }
    else if (characteristic == _deviceInformationCharacteristics.hardware)
    {
        if (characteristic.value.bytes)
        {
            self.hardwareVersion = [NSString stringWithUTF8String:[characteristic.value bytes]];
        }
        else
        {
            RLYLogFunction(@"Error reading value of hardware version characteristic: %@", error);
        }
    }
    else if (characteristic == _deviceInformationCharacteristics.bootloader)
    {
        if (characteristic.value.bytes)
        {
            self.bootloaderVersion = [NSString stringWithUTF8String:characteristic.value.bytes];
        }
        else
        {
            RLYLogFunction(@"Error reading value of bootloader version characteristic: %@", error);
        }
    }
    else if (characteristic == _deviceInformationCharacteristics.chip)
    {
        if (characteristic.value.bytes)
        {
            self.chipVersion = [NSString stringWithUTF8String:characteristic.value.bytes];
        }
        else
        {
            RLYLogFunction(@"Error reading value of chip version characteristic: %@", error);
        }
    }
    else if (characteristic == _deviceInformationCharacteristics.softdevice)
    {
        if (characteristic.value.bytes)
        {
            self.softdeviceVersion = [NSString stringWithUTF8String:characteristic.value.bytes];
        }
        else
        {
            RLYLogFunction(@"Error reading value of softdevice version characteristic: %@", error);
        }
    }
    else if (characteristic == _ringlyCharacteristics.bond)
    {
        if (characteristic.value.length > 0)
        {
            self.pairState = ((uint8_t*)characteristic.value.bytes)[0]
                           ? RLYPeripheralPairStatePaired
                           : RLYPeripheralPairStateUnpaired;
        }
    }
    else if (characteristic == _ringlyCharacteristics.configurationHash)
    {
        if (characteristic.value.length == sizeof(uint64_t))
        {
            uint64_t hash = 0;
            [characteristic.value getBytes:&hash length:sizeof(hash)];
            
            for (NSArray *blocks in _configurationHashBlocks)
            {
                void(^callback)(uint64_t) = blocks[0];
                callback(hash);
            }
        }
        else
        {
            NSError *error = RLYPeripheralError(RLYPeripheralErrorCodeIncorrectLength);
            
            for (NSArray *blocks in _configurationHashBlocks)
            {
                void(^callback)(NSError*) = blocks[1];
                callback(error);
            }
        }
        
        [_configurationHashBlocks removeAllObjects];
    }
    else if (characteristic == _activityCharacteristics.trackingData)
    {
        NSData *data = characteristic.value;

        if (data)
        {
            [RLYActivityTrackingUpdate parseActivityTrackingCharacteristicData:data withUpdateCallback:^(RLYActivityTrackingUpdate* update) {
                [_observers enumerateObservers:^(id  _Nonnull observer) {
                    if ([observer respondsToSelector:@selector(peripheral:readActivityTrackingUpdate:)])
                    {
                        [observer peripheral:self readActivityTrackingUpdate:update];
                    }
                }];
            } errorCallback:^(NSError* error) {
                [_observers enumerateObservers:^(id  _Nonnull observer) {
                    if ([observer respondsToSelector:@selector(peripheral:encounteredErrorWhileReadingActivityTrackingUpdates:)])
                    {
                        [observer peripheral:self encounteredErrorWhileReadingActivityTrackingUpdates:error];
                    }
                }];
            } completionCallback:^{
                [_observers enumerateObservers:^(id  _Nonnull observer) {
                    if ([observer respondsToSelector:@selector(peripheralCompletedReadingActivityData:)])
                    {
                        [observer peripheralCompletedReadingActivityData:self];
                    }
                }];
            }];
        }
    }
    else if (characteristic == _loggingCharacteristics.flash)
    {
        NSData *data = characteristic.value;

        if (data)
        {
            [_observers enumerateObservers:^(id  _Nonnull observer) {
                if ([observer respondsToSelector:@selector(peripheral:readFlashLogData:)])
                {
                    [observer peripheral:self readFlashLogData:data];
                }
            }];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // Create a set with the characteristic that has been updated removed. We use this set to get the remaining count
    // for logging, and later assign it to the characteristicsWaiting... property.
    NSMutableSet *set = [NSMutableSet setWithSet:_characteristicsWaitingForNotificationCallback];
    [set removeObject:characteristic];

    if (error)
    {
        // If there was an error, add it to the validation errors array. It's important to do this before we change
        // characteristicsWaiting..., because if that set becomes empty while the validation errors array if empty, the
        // peripheral might be considered validated.
        [self addValidationError:error];

        RLYLogFunction(@"%@ is not notifying on “%@”, %lu characteristics remain, error was: %@",
                       [RLYPeripheral UUIDDescriptionForCharacteristicWithUUID:characteristic.UUID],
                       self.lastFourMAC,
                       (unsigned long)set.count,
                       [error localizedDescription]);
    }
    else
    {
        RLYLogFunction(@"“%@” is notifying on “%@”, %lu characteristics remain",
                       [RLYPeripheral UUIDDescriptionForCharacteristicWithUUID:characteristic.UUID],
                       self.lastFourMAC,
                       (unsigned long)set.count);
    }

    // now that we've added an error if necessary, it's safe to change this property
    self.characteristicsWaitingForNotificationCallback = set;

    // special handling for the activity notifications characteristics
    if (characteristic == _activityCharacteristics.trackingData && !error)
    {
        self.subscribedToActivityNotifications = YES;   
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        RLYLogFunction(@"Error writing to characteristic %@ on “%@”: %@", characteristic.UUID, self.lastFourMAC, error);
    }
}

-(void)peripheralDidUpdateName:(CBPeripheral *)peripheral
{
    self.name = peripheral.name;
}

#pragma mark - ANCS Version 1 Parser Delegate
-(void)ANCSV1Parser:(RLYANCSV1Parser *)parser parsedNotification:(RLYANCSNotification *)notification
{
    [_observers enumerateObservers:^void(id<RLYPeripheralObserver> __nonnull observer) {
        if ([observer respondsToSelector:@selector(peripheral:didReceiveANCSNotification:)])
        {
            [observer peripheral:self didReceiveANCSNotification:notification];
        }
    }];
}

-(void)ANCSV1Parser:(RLYANCSV1Parser *)parser failedToParseNotificationWithError:(NSError *)error
{
    RLYLogFunction(@"Error parsing ANCSv1 notification: %@", error);
}

#pragma mark - Service Descriptions
+(nullable NSString*)descriptionForServiceWithUUID:(CBUUID*)UUID
{
    if ([UUID isEqual:[RLYUUID ringlyServiceShort]] || [UUID isEqual:[RLYUUID ringlyServiceLong]])
    {
        return @"Ringly";
    }
    else if ([UUID isEqual:[RLYUUID deviceInformationService]])
    {
        return @"Device Information";
    }
    else if ([UUID isEqual:[RLYUUID batteryService]])
    {
        return @"Battery";
    }
    else if ([UUID isEqual:[RLYUUID loggingServiceShort]] || [UUID isEqual:[RLYUUID loggingServiceLong]])
    {
        return @"Logging";
    }
    else if ([UUID isEqual:[RLYUUID activityService]])
    {
        return @"Activity";
    }
    else
    {
        return nil;
    }
}

+(NSString *)descriptionForCharacteristicWithUUID:(CBUUID *)UUID
{
    if ([UUID isEqual:[RLYUUID writeCharacteristicShort]] ||
        [UUID isEqual:[RLYUUID writeCharacteristicLong]])
    {
        return @"Control Point";
    }
    else if ([UUID isEqual:[RLYUUID messageCharacteristicShort]] ||
             [UUID isEqual:[RLYUUID messageCharacteristicLong]])
    {
        return @"Message";
    }
    else if ([UUID isEqual:[RLYUUID ANCSVersion1CharacteristicShort]] ||
             [UUID isEqual:[RLYUUID ANCSVersion1CharacteristicLong]])
    {
        return @"ANCS v2";
    }
    else if ([UUID isEqual:[RLYUUID applicationVersionCharacteristic]])
    {
        return @"Application Version";
    }
    else if ([UUID isEqual:[RLYUUID hardwareVersionCharacteristic]])
    {
        return @"Hardware Version";
    }
    else if ([UUID isEqual:[RLYUUID manufacturerCharacteristic]])
    {
        return @"Manufacturer";
    }
    else if ([UUID isEqual:[RLYUUID batteryLevelCharacteristic]])
    {
        return @"Battery Level";
    }
    else if ([UUID isEqual:[RLYUUID chargeStateCharacteristic]])
    {
        return @"Charge State";
    }
    else if ([UUID isEqual:[RLYUUID bondCharacteristic]])
    {
        return @"Bond";
    }
    else if ([UUID isEqual:[RLYUUID clearBondCharacteristic]])
    {
        return @"Clear Bond";
    }
    else if ([UUID isEqual:[RLYUUID ANCSVersion2Characteristic]])
    {
        return @"ANCS v2";
    }
    else if ([UUID isEqual:[RLYUUID activityServiceControlPointCharacteristic]])
    {
        return @"Control Point";
    }
    else if ([UUID isEqual:[RLYUUID activityServiceTrackingDataCharacteristic]])
    {
        return @"Tracking Data";
    }
    else if ([UUID isEqual:[RLYUUID loggingServiceFlashLogCharacteristicLong]] ||
             [UUID isEqual:[RLYUUID loggingServiceFlashLogCharacteristicShort]])
    {
        return @"Flash Log";
    }
    else if ([UUID isEqual:[RLYUUID loggingServiceRequestCharacteristicLong]] ||
             [UUID isEqual:[RLYUUID loggingServiceRequestCharacteristicShort]])
    {
        return @"Request";
    }
    else
    {
        return nil;
    }
}

+(NSString*)UUIDDescriptionForCharacteristicWithUUID:(CBUUID*)UUID
{
    return [self descriptionForCharacteristicWithUUID:UUID] ?: UUID.UUIDString;
}

@end

NSString* RLYPeripheralValidationStateToString(RLYPeripheralValidationState validationState)
{
    switch (validationState)
    {
        case RLYPeripheralValidationStateValidated:
            return @"Validated";
        case RLYPeripheralValidationStateMissingServices:
            return @"Missing services";
        case RLYPeripheralValidationStateHasValidationErrors:
            return @"Has validation errors";
        case RLYPeripheralValidationStateMissingRinglyCharacteristics:
            return @"Missing Ringly characteristics";
        case RLYPeripheralValidationStateMissingBatteryCharacteristics:
            return @"Missing battery characteristics";
        case RLYPeripheralValidationStateMissingActivityTrackingCharacteristics:
            return @"Missing activity tracking characteristics";
        case RLYPeripheralValidationStateMissingDeviceInformationCharacteristics:
            return @"Missing device information characteristics";
        case RLYPeripheralValidationStateWaitingForNotificationStateConformation:
            return @"Waiting for notification state confirmation";
    }
}
