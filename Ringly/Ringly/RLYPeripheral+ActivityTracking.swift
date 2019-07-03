import ReactiveSwift
import RinglyActivityTracking
import RinglyExtensions
import RinglyKit
import ReactiveRinglyKit
import enum Result.NoError

// MARK: - Managing Activity Tracking
extension Reactive where Base: RLYPeripheral
{
    func performActivityTrackingActions(syncingWith activityTrackingService: ActivityTrackingService)
        -> SignalProducer<(), NoError>
    {
        // determine when to read activity tracking data from the peripheral
        let activeProducer = UIApplication.shared.activeProducer

        // updates whenever an activity tracking peripheral connects or disconnects
        let activityTrackingPeripheral = ready
            .ifSupports({ $0.reactive.activityTrackingSupport })
            .debounce(8, on: QueueScheduler.main, valuesPassingTest: { $0 != nil })
            .skipRepeats(==)

        let readTriggerProducer = activityTrackingPeripheral
            // enable activity tracking on the peripheral
            .on(value: { optional in
                guard let peripheral = optional else { return }
                SLogActivityTracking("Enabling activity tracking on \(peripheral.loggingName)")
                peripheral.enableActivityTracking()
            })
            .flatMapOptional(.latest, transform: { peripheral in
                // once foregrounded, immediately read data, then continue reading every minute. in the background,
                // just read data every 20 minutes.
                activeProducer.flatMap(.latest, transform: { foregrounded -> SignalProducer<ActivityTrackingReadTrigger, NoError> in
                    
                    let backgroundTimer = timer(interval: .seconds(1200), on: QueueScheduler.main)
                                                .map(ActivityTrackingReadTrigger.backgroundTimer)
                    
                    let manualSync = SignalProducer.`defer` {
                        return SignalProducer([
                            SignalProducer(value: ActivityTrackingReadTrigger.manualSync(.foreground)),
                            SignalProducer(activityTrackingService.syncSignal)
                                .map(ActivityTrackingReadTrigger.manualSync)
                            ]).flatten(.concat)
                    }
                    
                    return foregrounded ? manualSync : backgroundTimer
                })
            })
            .skipNil()
            .throttle(30, on: QueueScheduler.main)

        // the latest date that we have written for this peripheral
        let latestDateProducer = MACAddress.promoteErrors(NSError.self)
            .mapOptionalFlat({ Int64($0, radix: 16) })
            .flatMapOptionalFlat(.latest, transform: { macAddress -> SignalProducer<Date?, NSError> in
                activityTrackingService.stepsBoundaryDateProducer(ascending: false, sourceMACAddress: macAddress)
            })
            .skipRepeats(==)

        // read activity tracking data from the peripheral
        let readData = latestDateProducer.sample(with: readTriggerProducer)
            .flatMap(.latest, transform: { [weak base] date, trigger in
                base?.activityTrackingReadProducer(since: date, because: trigger) ?? SignalProducer.empty
            })

        return readData.ignoreValues().flatMapError({ error in
            SLogActivityTracking("Fatal error reading activity tracking data: \(error)")
            return SignalProducer.empty
        })
    }
}

// MARK: - Enabling Activity Tracking
extension RLYPeripheral
{
    fileprivate func enableActivityTracking()
    {
        do
        {
            // if necessary, activate activity tracking on the peripheral
            try self.updateActivityTrackingWith(
                enabled: true,
                sensitivity: .sensitivity4G,
                mode: .normal,
                minimumPeakIntensity: type.minimumPeakIntensity,
                minimumPeakHeight: type.minimumPeakHeight
            )
        }
        catch let error as NSError
        {
            SLogActivityTracking("Error enabling activity tracking: \(error)")
        }
    }

    fileprivate func activityTrackingReadProducer(since latestDate: Date?, because trigger: ActivityTrackingReadTrigger)
        -> SignalProducer<(), NoError>
    {
        return reactive.subscribedToActivityNotifications.skipRepeats()
            .ignore(false)
            .take(first: 1)
            .on(starting: { [weak self] subscribed in
                guard let strong = self else { return }

                do
                {
                    let date = try latestDate.map(RLYActivityTrackingDate.init)
                        ?? RLYActivityTrackingDate(minute: RLYActivityTrackingMinuteMin)

                    SLogBluetooth("Reading activity tracking data since \(date) from \(strong.loggingName) because \(trigger)")

                    try strong.readActivityTrackingDataSince(date: date)
                }
                catch let error as NSError
                {
                    SLogBluetooth(
                        "Activity tracking error on peripheral \(strong.loggingName): \(error))"
                    )
                }
            })
            .ignoreValues()
    }
}

extension RLYPeripheralType
{
    fileprivate var minimumPeakIntensity: RLYActivityTrackingPeakIntensity
    {
        switch self
        {
        case .ring:
            return 1000
        default:
            return 850
        }
    }

    fileprivate var minimumPeakHeight: RLYActivityTrackingPeakHeight
    {
        switch self
        {
        case .ring:
            return 500
        default:
            return 375
        }
    }
}

// MARK: - Activity Tracking Availability
extension Reactive where Base: RLYPeripheral
{
    /// A producer describing the availability of activity tracking on the receiver.
    var activityTrackingAvailability: SignalProducer<ActivityTrackingAvailability, NoError>
    {
        return activityTrackingSupport.combineLatest(with: applicationVersion)
            .map({ support, optionalVersion -> ActivityTrackingAvailability in
                switch support
                {
                case .undetermined:
                    return .undetermined
                case .unsupported:
                    return optionalVersion
                        .flatMap({ $0.components(separatedBy: ".").first })
                        .map({ component -> ActivityTrackingAvailability in
                            switch component
                            {
                            case "1":
                                return .unavailable
                            case "2":
                                return .updateRequired
                            default:
                                return .undetermined
                            }
                        }) ?? .undetermined
                case .supported:
                    return .available
                }
            })
            .skipRepeats()
    }
}

/// Describes whether or not the activity tracking feature is available on a peripheral.
enum ActivityTrackingAvailability
{
    /// The information required to determine the availability of activity tracking on the peripheral is not available
    /// yet.
    case undetermined

    /// Activity tracking is unavailable on the peripheral.
    case unavailable

    /// Activity tracking can be added to the peripheral, but an update is required.
    case updateRequired

    /// Activity tracking is available on the peripheral.
    case available
}


enum ActivityTrackingReadTrigger
{
    case manualSync(ActivityTrackingManualReadTriggerSource)
    case backgroundTimer(Date)
}

extension ActivityTrackingReadTrigger: CustomStringConvertible
{

    var description: String
    {
        switch self
        {
        case let .backgroundTimer(date):
            return "background timer fired at \(date)"
        case let .manualSync(source):
            return "sync triggered from \(source)"
        }
    }
}
