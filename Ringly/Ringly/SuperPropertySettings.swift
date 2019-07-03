import ReactiveSwift
import class RinglyActivityTracking.ActivityTrackingService
import enum HealthKit.HKAuthorizationStatus
import enum Result.NoError

struct SuperPropertySetting
{
    let key: String
    let value: String?
}

extension SuperPropertySetting
{
    /// A producer for super property settings, derived from application services.
    ///
    /// - parameter activity:     An activity tracking service to use for determining super properties.
    /// - parameter applications: An applications service to use for determining super properties.
    /// - parameter contacts:     A contacts service to use for determining super properties.
    /// - parameter peripherals:  A peripherals service to use for determining super properties.
    /// - parameter preferences:  A preferences service to use for determining super properties.
    static func producer(activity: ActivityTrackingService,
                         applications: ApplicationsService,
                         contacts: ContactsService,
                         peripherals: PeripheralsService,
                         preferences: Preferences)
        -> SignalProducer<SuperPropertySetting, NoError>
    {
        return SignalProducer.merge(
            activity.superPropertySettings(),
            applications.superPropertySettings(),
            contacts.superPropertySettings(key: "Enabled Contacts"),
            peripherals.superPropertySettings(),
            preferences.superPropertySettings()
        )
    }
}

extension ActivityTrackingService
{
    fileprivate func superPropertySettings() -> SignalProducer<SuperPropertySetting, NoError>
    {
        return healthKitAuthorization.producer.superPropertySettings(key: "System Health Authorization")
    }
}

extension ApplicationsService
{
    fileprivate func superPropertySettings() -> SignalProducer<SuperPropertySetting, NoError>
    {
        let defaultConfigurations = ApplicationConfiguration.defaultActivatedConfigurations(for: supportedApplications)

        return SignalProducer.merge(
            superPropertySettings(key: "Enabled Notifications"),
            activatedConfigurations.producer.map({ $0 != defaultConfigurations }).skipRepeats()
                .superPropertySettings(key: "Customized Notifications")
        )
    }
}

extension ConfigurationService
{
    fileprivate func superPropertySettings(key: String) -> SignalProducer<SuperPropertySetting, NoError>
    {
        return activatedConfigurations.producer.map({ $0.count }).superPropertySettings(key: key)
    }
}

extension PeripheralsService
{
    
    fileprivate func superPropertySettings() -> SignalProducer<SuperPropertySetting, NoError>
    {
        return activatedPeripheral.producer.flatMap(.latest, transform: { peripheral -> SignalProducer<SuperPropertySetting, NoError> in
            let connectedProducer = (peripheral?.reactive.connected ?? SignalProducer(value: false))
                .superPropertySettings(key: "Connected")

            let batteryLevelProducer = (peripheral?.reactive.batteryCharge.map({ $0 ?? 0 }) ?? SignalProducer(value: 0))
                .superPropertySettings(key: "Battery Level")

            let chargeStateProducer = (peripheral?.reactive.batteryState.map({ $0 ?? .notCharging }) ?? SignalProducer(value: .notCharging))
                .superPropertySettings(key: "Charge State")

            let applicationProducer = (peripheral?.reactive.applicationVersion ?? SignalProducer(value: String?.none))
                .superPropertySettings(key: "Firmware Revision")

            let bootloaderProducer = (peripheral?.reactive.bootloaderVersion ?? SignalProducer(value: String?.none))
                .superPropertySettings(key: "Bootloader Revision")

            let hardwareProducer = (peripheral?.reactive.hardwareVersion ?? SignalProducer(value: String?.none))
                .superPropertySettings(key: "Hardware Revision")

            return SignalProducer.merge(
                connectedProducer,
                batteryLevelProducer,
                chargeStateProducer,
                applicationProducer,
                bootloaderProducer,
                hardwareProducer
            )
        })
    }
}

extension Preferences
{
    
    fileprivate func superPropertySettings() -> SignalProducer<SuperPropertySetting, NoError>
    {
        return SignalProducer.merge(
            connectionTaps.producer.superPropertySettings(key: "Connection Taps Setting"),
            disconnectVibrations.producer.superPropertySettings(key: "Out Of Range Setting"),
            sleepMode.producer.superPropertySettings(key: "Sleep Mode Setting"),
            innerRing.producer.superPropertySettings(key: "Inner Ring Setting")
        )
    }
}

extension SignalProducer where Value: AnalyticsPropertyValueType
{
    
    fileprivate func superPropertySettings(key: String) -> SignalProducer<SuperPropertySetting, Error>
    {
        return map({ SuperPropertySetting(key: key, value: $0.analyticsString) })
    }
}

extension SignalProducer where Value: OptionalProtocol, Value.Wrapped: AnalyticsPropertyValueType
{
    
    fileprivate func superPropertySettings(key: String) -> SignalProducer<SuperPropertySetting, Error>
    {
        return map({ SuperPropertySetting(key: key, value: $0.optional?.analyticsString) })
    }
}

extension HKAuthorizationStatus: AnalyticsPropertyValueType
{
    var analyticsString: String
    {
        switch self
        {
        case .notDetermined:
            return "Not Determined"
        case .sharingAuthorized:
            return "Authorized"
        case .sharingDenied:
            return "Denied"
        }
    }
}
