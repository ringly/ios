import Foundation
import ReactiveSwift
import Result
import RinglyExtensions
import RinglyKit

private let LowBatteryWarning = 10
private let LowBatterySendAgain = 20
private let LowBatteryKey = "LowBatteryKey"
private let FullBatteryNotif = 95
private let FullBatteryKey = "FullBatteryKey"
private let ChargeRinglyKey = "ChargeRinglyKey"

/// Sends local notifications when the peripheral's battery charge is low.
extension Reactive where Base: RLYPeripheral
{
    /// A producer that, once started, sends low battery notifications for the receiver.
    ///
    /// - Parameters:
    ///   - preferences: The preferences object to store settings in.
    ///   - activatedProducer: A producer for whether or not the peripheral is activated. This is used to determine
    ///                        whether or not a notification should be sent.
    func sendLowBatteryNotifications(preferences: Preferences, activatedProducer: SignalProducer<Bool, NoError>)
        -> SignalProducer<(), NoError>
    {
        let peripheral = base

        return RLYPeripheral.sendLowBatteryNotifications(
            peripheralIdentifier: base.identifier,
            dataSource: PeripheralBatteryDataSource(peripheral: base),
            stateSource: preferences,
            sendAt: 10,
            sendAgainAt: 20,
            send: { charge in
                UIApplication.shared.presentLocalNotificationNow(.lowBatteryNotification(
                    peripheral: peripheral,
                    charge: charge
                ))
            }
        )
    }
    
    /// A producer that, once started, sends full battery notifications for the receiver.
    ///
    /// - Parameters:
    ///   - preferences: The preferences object to store settings in.
    ///   - activatedProducer: A producer for whether or not the peripheral is activated. This is used to determine
    ///                        whether or not a notification should be sent.
    func sendFullBatteryNotifications(preferences: Preferences, activatedProducer: SignalProducer<Bool, NoError>)
        -> SignalProducer<(), NoError>
    {
        return RLYPeripheral.sendFullBatteryNotifications(
            peripheralIdentifier: base.identifier,
            dataSource: PeripheralBatteryDataSource(peripheral: base),
            stateSource: preferences,
            activatedProducer: activatedProducer,
            sendAt: 95,
            sendAgainAt: 75,
            send: { charge in
                UIApplication.shared.presentLocalNotificationNow(.fullBatteryNotification())
        }
        )
    }
    
    /// A producer that, once started, sends charge battery notifications for the receiver.
    ///
    /// - Parameters:
    ///   - preferences: The preferences object to store settings in.
    ///   - activatedProducer: A producer for whether or not the peripheral is activated. This is used to determine
    ///                        whether or not a notification should be sent.
    func sendChargeBatteryNotifications(preferences: Preferences, activatedProducer: SignalProducer<Bool, NoError>)
        -> SignalProducer<(), NoError>
    {
        return RLYPeripheral.sendChargeBatteryNotifications(
            peripheralIdentifier: base.identifier,
            dataSource: PeripheralBatteryDataSource(peripheral: base),
            stateSource: preferences,
            activatedProducer: activatedProducer,
            sendAt: 75,
            send: { date in
                UIApplication.shared.cancelChargeNotifications(ChargeNotification.charge)
                UIApplication.shared.scheduleLocalNotification(.chargeNotification(date: date))
                SLogAppleNotifications("Scheduled charge notification for \(date)")
        }
        )
    }
}

extension RLYPeripheral
{
    /// A producer that, once started, sends low battery notifications for the receiver, filtering notifications based
    /// on input from an activation producer.
    ///
    /// - Parameters:
    ///   - peripheralIdentifier: The peripheral identifier this service is tracking. This value is used with
    ///                           `stateSource` to ensure that duplicate notifications are not sent.
    ///   - dataSource: The data source for the service.
    ///   - stateSource: The state source for the service.
    ///   - activatedProducer: A producer for whether or not the peripheral is activated. This is used to determine
    ///                        whether or not a notification should be sent.
    ///   - sendAt: The battery value at which `send` should be invoked.
    ///   - sendAgainAt: The battery value at which `send`, once invoked, should be eligible to be invoked again.
    ///   - send: A function to perform the desired low battery action.
    static func sendLowBatteryNotifications(peripheralIdentifier: UUID,
                                            dataSource: BatteryServiceDataSource,
                                            stateSource: BatteryServiceStateSource,
                                            activatedProducer: SignalProducer<Bool, NoError>,
                                            sendAt: Int,
                                            sendAgainAt: Int,
                                            send: @escaping (_ charge: Int) -> ())
        -> SignalProducer<(), NoError>
    {
        let activated = Property(initial: false, then: activatedProducer)

        return sendLowBatteryNotifications(
            peripheralIdentifier: peripheralIdentifier,
            dataSource: dataSource,
            stateSource: stateSource,
            sendAt: sendAt,
            sendAgainAt: sendAgainAt,
            send: { charge in
                if activated.value
                {
                    send(charge)
                }
            }
        )
    }

    /// Initializes a low battery service.
    ///
    /// - Parameters:
    ///   - peripheralIdentifier: The peripheral identifier this service is tracking. This value is used with
    ///                           `stateSource` to ensure that duplicate notifications are not sent.
    ///   - dataSource: The data source for the service.
    ///   - stateSource: The state source for the service.
    ///   - sendAt: The battery value at which `send` should be invoked.
    ///   - sendAgainAt: The battery value at which `send`, once invoked, should be eligible to be invoked again.
    ///   - send: A function to perform the desired low battery action.
    static func sendLowBatteryNotifications(peripheralIdentifier: UUID,
                                            dataSource: BatteryServiceDataSource,
                                            stateSource: BatteryServiceStateSource,
                                            sendAt: Int,
                                            sendAgainAt: Int,
                                            send: @escaping (_ charge: Int) -> ())
        -> SignalProducer<(), NoError>
    {
        return dataSource.batteryChargeProducer.combineLatest(with: dataSource.batteryStateProducer)
            // only send nexts when we know both the charge and the charging state
            .map(unwrap)
            .skipNil()

            // add the enabled preference to the tuple, and repack
            .combineLatest(with: stateSource.batteryAlertsEnabled.producer)
            .map(append)

            // send low battery notifications
            .on(value: { charge, state, enabled in
                let identifiers = stateSource.lowBatterySentIdentifiers

                if charge <= sendAt &&
                   charge > 0 &&
                   state == .notCharging &&
                   !identifiers.value.contains(peripheralIdentifier) &&
                   enabled
                {
                    identifiers.value.insert(peripheralIdentifier)
                    send(charge)
                }
                else if charge > sendAgainAt && identifiers.value.contains(peripheralIdentifier)
                {
                    identifiers.value.remove(peripheralIdentifier)
                }
            })
            .ignoreValues()
    }

    /// A producer that, once started, sends full battery notifications for the receiver, filtering notifications based
    /// on input from an activation producer.
    ///
    /// - Parameters:
    ///   - peripheralIdentifier: The peripheral identifier this service is tracking. This value is used with
    ///                           `stateSource` to ensure that duplicate notifications are not sent.
    ///   - dataSource: The data source for the service.
    ///   - stateSource: The state source for the service.
    ///   - activatedProducer: A producer for whether or not the peripheral is activated. This is used to determine
    ///                        whether or not a notification should be sent.
    ///   - sendAt: The battery value at which `send` should be invoked.
    ///   - send: A function to perform the desired full battery action.
    static func sendFullBatteryNotifications(peripheralIdentifier: UUID,
                                             dataSource: BatteryServiceDataSource,
                                             stateSource: BatteryServiceStateSource,
                                             activatedProducer: SignalProducer<Bool, NoError>,
                                             sendAt: Int,
                                             sendAgainAt: Int,
                                             send: @escaping (_ charge: Int) -> ())
        -> SignalProducer<(), NoError>
    {
        let activated = Property(initial: false, then: activatedProducer)

        return sendFullBatteryNotifications(
            peripheralIdentifier: peripheralIdentifier,
            dataSource: dataSource,
            stateSource: stateSource,
            sendAt: sendAt,
            sendAgainAt: sendAgainAt,
            send: { charge in
                if activated.value {
                    send(charge)
                }
        })
    }
    
    /// Initializes a full battery service.
    ///
    /// - Parameters:
    ///   - peripheralIdentifier: The peripheral identifier this service is tracking. This value is used with
    ///                           `stateSource` to ensure that duplicate notifications are not sent.
    ///   - dataSource: The data source for the service.
    ///   - stateSource: The state source for the service.
    ///   - sendAt: The battery value at which `send` should be invoked.
    ///   - send: A function to perform the desired full battery action.
    static func sendFullBatteryNotifications(peripheralIdentifier: UUID,
                                             dataSource: BatteryServiceDataSource,
                                             stateSource: BatteryServiceStateSource,
                                             sendAt: Int,
                                             sendAgainAt: Int,
                                             send: @escaping (_ charge: Int) -> ())
        -> SignalProducer<(), NoError>
    {
        return dataSource.batteryChargeProducer.combineLatest(with: dataSource.batteryStateProducer)
            // only send nexts when we know both the charge and the charging state
            .map(unwrap)
            .skipNil()
            
            // add the enabled preference to the tuple, and repack
            .combineLatest(with: stateSource.batteryAlertsEnabled.producer)
            .map(append)
            
            // send full battery notifications
            .on(value: { charge, state, enabled in
                let identifiers = stateSource.fullBatterySentIdentifiers
                
                if charge >= sendAt &&
                    (state == .charged || state == .charging) &&
                    !identifiers.value.contains(peripheralIdentifier) &&
                    enabled
                {
                    identifiers.value.insert(peripheralIdentifier)
                    send(charge)
                }
                    
                    // should not send if battery is less than 75 percent charged
                else if charge < sendAgainAt && identifiers.value.contains(peripheralIdentifier)
                {
                    identifiers.value.remove(peripheralIdentifier)
                }
            })
            .ignoreValues()
    }
    
    /// A producer that, once started, sends charge battery reminder notifications for the receiver, filtering notifications based
    /// on input from an activation producer.
    ///
    /// - Parameters:
    ///   - peripheralIdentifier: The peripheral identifier this service is tracking. This value is used with
    ///                           `stateSource` to ensure that duplicate notifications are not sent.
    ///   - dataSource: The data source for the service.
    ///   - stateSource: The state source for the service.
    ///   - activatedProducer: A producer for whether or not the peripheral is activated. This is used to determine
    ///                        whether or not a notification should be sent.
    ///   - sendAt: The battery value at which `send` should be invoked.
    ///   - send: A function to perform the desired full battery action.
    static func sendChargeBatteryNotifications(peripheralIdentifier: UUID,
                                             dataSource: BatteryServiceDataSource,
                                             stateSource: BatteryServiceStateSource,
                                             activatedProducer: SignalProducer<Bool, NoError>,
                                             sendAt: Int,
                                             send: @escaping (_ date: Date) -> ())
        -> SignalProducer<(), NoError>
    {
        let activated = Property(initial: false, then: activatedProducer)
        
        return sendChargeBatteryNotifications(
            peripheralIdentifier: peripheralIdentifier,
            dataSource: dataSource,
            stateSource: stateSource,
            sendAt: sendAt,
            send: { date in
                if activated.value {
                    send(date)
                }
        })
    }
    
    /// Initializes a charge battery reminder service.
    ///
    /// - Parameters:
    ///   - peripheralIdentifier: The peripheral identifier this service is tracking. This value is used with
    ///                           `stateSource` to ensure that duplicate notifications are not sent.
    ///   - dataSource: The data source for the service.
    ///   - stateSource: The state source for the service.
    ///   - sendAt: The battery value at which `send` should be invoked.
    ///   - send: A function to perform the desired full battery action.
    static func sendChargeBatteryNotifications(peripheralIdentifier: UUID,
                                             dataSource: BatteryServiceDataSource,
                                             stateSource: BatteryServiceStateSource,
                                             sendAt: Int,
                                             send: @escaping (_ charge: Date) -> ())
        -> SignalProducer<(), NoError>
    {
        return dataSource.batteryChargeProducer.combineLatest(with: dataSource.batteryStateProducer)
            .map(unwrap)
            .skipNil()
            
            .combineLatest(with: stateSource.batteryAlertsEnabled.producer)
            .map(append)
        
            // send charge battery notifications
            .on(value: { charge, state, enabled in
                    let identifiers = stateSource.chargeBatterySentIdentifiers
                    let notification = ChargeNotification.charge
                    if enabled {
                        notification.stateProperty(in: stateSource).modify({ scheduleState in
                        
                            switch scheduleState
                            {
                            case .unscheduled:
                                if let date = Calendar.current.date(bySettingHour: 21, minute: 30, second: 0, of: Date())
                                {
                                    if !identifiers.value.contains(peripheralIdentifier) {
                                        send(date)
                                        scheduleState = .scheduled
                                        identifiers.value.insert(peripheralIdentifier)
                                    }
                                }
                            case .scheduled:
                                if (state == .charging || state == .charged || charge > sendAt) &&
                                    identifiers.value.contains(peripheralIdentifier)
                                {
                                    if let date = Calendar.current
                                        .date(bySettingHour: 21, minute: 30, second: 0,
                                              of: Date().addingTimeInterval(60 * 60 * 24))
                                    {
                                        send(date)
                                    }
                                }
                            }
                        })
                    }
                    else {
                        UIApplication.shared.cancelChargeNotifications(notification)
                        notification.stateProperty(in: stateSource).value = .unscheduled
                        identifiers.value.remove(peripheralIdentifier)
                        SLogAppleNotifications("Battery alerts disabled, cancelled charge notification")
                    }
            })
            .ignoreValues()
    }
}

// MARK: - Battery Service Data Source

/// A protocol for types providing the data for battery alert notifications.
protocol BatteryServiceDataSource
{
    /// A signal producer of the current battery charge value.
    var batteryChargeProducer: SignalProducer<Int?, NoError> { get }

    /// A signal provider of the current battery state value.
    var batteryStateProducer: SignalProducer<RLYPeripheralBatteryState?, NoError> { get }
}

// MARK: - Bluetooth Service Integration

/// A battery data source wrapper for `RLYPeripheral`.
struct PeripheralBatteryDataSource: BatteryServiceDataSource
{
    let peripheral: RLYPeripheral

    var batteryChargeProducer: SignalProducer<Int?, NoError>
    {
        return peripheral.reactive.batteryCharge
    }

    var batteryStateProducer: SignalProducer<RLYPeripheralBatteryState?, NoError>
    {
        return peripheral.reactive.batteryState
    }
}

// MARK: - Battery Service

/// A state storage type for `BatteryService`.
protocol BatteryServiceStateSource
{
    /// A property describing which peripherals a low battery notification has already been sent for. The low battery
    /// service will read this property's value when ready to send a low battery notification, and will modify the
    /// property when a low battery notification is sent, or becomes eligible for sending again.
    var lowBatterySentIdentifiers: MutableProperty<Set<UUID>> { get }

    /// A property describing which peripherals a full battery notification has already been sent for. The full battery
    /// service will read this property's value when ready to send a full battery notification, and will modify the
    /// property when a full battery notification is sent, or becomes eligible for sending again.
    var fullBatterySentIdentifiers: MutableProperty<Set<UUID>> { get }
    
    /// A property describing which peripherals a charge battery notification has already been sent for. The charge battery
    /// service will read this property's value when ready to send a charge battery notification, and will modify the
    /// property when a charge battery notification is sent, or becomes eligible for sending again.
    var chargeBatterySentIdentifiers: MutableProperty<Set<UUID>> { get }

    /// A property describing which peripherals a charge battery notification has already been sent for. The charge battery
    /// service will read this property's value when ready to send a charge battery notification, and will modify the
    /// property when a charge battery notification is sent, or becomes eligible for sending again.
    var chargeNotificationState: MutableProperty<ChargeNotificationState> { get }

    /// A property describing whether or not low battery notifications should be sent at all. The low battery service
    /// will read this property's value, but will not write to it. The type is `MutableProperty` to make integration
    /// with `Preferences` easy, it ought to be `Property` or a generic constrained to `PropertyType`, but that would
    /// make the code much more difficult.
    var batteryAlertsEnabled: MutableProperty<Bool> { get }
}

// MARK: - Preferences Integration
extension Preferences: BatteryServiceStateSource {}

// MARK: - Local Notification Extensions
extension LocalNotification
{
    /// `true` if the notification is a low battery notification.
    @nonobjc var isLowBattery: Bool
    {
        return userInfo?[LowBatteryKey] as? Bool ?? false
    }
    
    /// `true` if the notification is a full battery notification.
    @nonobjc var isFullBattery: Bool
    {
        return userInfo?[FullBatteryKey] as? Bool ?? false
    }
 
    /// `true` if the notification is a charge ringly notification.
    func isChargeRingly(_ chargeNotification: ChargeNotification) -> Bool
    {
        return userInfo?[ChargeRinglyKey] as? Bool ?? false
    }
}

extension UILocalNotification
{
    /**
     Creates a low battery notification.

     - parameter peripheral: The peripheral that is low on battery.
     - parameter charge:     The charge value, which will be displayed in the notification body text.
     */
    static func lowBatteryNotification(peripheral: RLYPeripheral, charge: Int) -> UILocalNotification
    {
        let notification = UILocalNotification()
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.alertTitle = tr(.lowBatteryNotificationText)
        notification.alertBody = tr(.lowBatteryNotificationDetailText(peripheral.displayNameRingly, charge))
        notification.userInfo = [LowBatteryKey: true]

        return notification
    }
    
    /**
     Creates a full battery notification.
     
     - parameter peripheral: The peripheral that is full on battery.
     - parameter charge:     The charge value, which will be displayed in the notification body text.
     */
    static func fullBatteryNotification() -> UILocalNotification
    {
        let notification = UILocalNotification()
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.alertTitle = tr(.fullBatteryNotificationText)
        notification.alertBody = tr(.fullBatteryNotificationDetailText)
        notification.userInfo = [FullBatteryKey: true]
        
        return notification
    }
    
    static func chargeNotification(date: Date) -> UILocalNotification
    {
        let notification = UILocalNotification()
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.fireDate = date
        notification.alertTitle = tr(.chargeBatteryNotificationText)
        notification.alertBody = tr(.chargeBatteryNotificationDetailText)
        notification.userInfo = [ChargeRinglyKey: true]
        
        return notification
    }
}

extension LocalNotificationScheduling
{
    fileprivate func cancelNotifications(matching: (UILocalNotification) -> Bool)
    {
        scheduledLocalNotifications?.filter(matching).forEach({ notification in
            cancelLocalNotification(notification)
            SLogAppleNotifications("Cancelled charge notification \(notification)")
        })
    }
    
    func cancelChargeNotifications(_ chargeNotification: ChargeNotification)
    {
        cancelNotifications(matching: { $0.isChargeRingly(chargeNotification) })
    }
}

enum ChargeNotification: String
{
    /// Charge notification
    case charge
}

extension ChargeNotification
{
    fileprivate var userInfoKey: String
    {
        return rawValue
    }
    
    /// An array of all mindful notifications.
    static var all: [ChargeNotification]
    {
        return [ .charge ]
    }
    
    func stateProperty(in chargePreference: BatteryServiceStateSource) -> MutableProperty<ChargeNotificationState>
    {
        return chargePreference.chargeNotificationState
    }
}

enum ChargeNotificationState: String
{
    /// The notification has not been scheduled.
    case unscheduled
    
    /// The notification has been scheduled.
    case scheduled
}
