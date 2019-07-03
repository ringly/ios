import Foundation
import HealthKit
import ReactiveSwift
import Result
import RinglyExtensions

public final class ActivityTrackingService: NSObject
{
    // MARK: - Initialization
    public init(healthKitService: HealthKitService?,
                backupStepsDataSource: StepsDataSource & SourcedStepsDataSource,
                backupMindfulMinuteDataSource: MindfulMinuteDataSource,
                retryBoundaryDateErrorsProducer: SignalProducer<(), NoError>,
                errorLogFunction: @escaping (String) -> ())
    {
        self.healthKitService = healthKitService
        self.backupStepsDataSource = backupStepsDataSource
        self.backupMindfulMinuteDataSource = backupMindfulMinuteDataSource

        // keep track of HealthKit authorization status
        healthKitAuthorization = healthKitService.map({ $0.authorizationStatus })
            ?? Property(value: .sharingDenied)

        // preload boundary dates to improve interface responsiveness
        let dateProperty = { ascending in
            ActivityTrackingService.dateProperty(
                healthKitService: healthKitService,
                backupStepsDataSource: backupStepsDataSource,
                retryProducer: retryBoundaryDateErrorsProducer,
                ascending: ascending
            )
        }
        
        currentAscendingBoundaryDate = dateProperty(true)
        currentDescendingBoundaryDate = dateProperty(false)

        // preload day boundary dates to improve interface responsiveness
        let boundsProducer = SignalProducer.combineLatest(
            Calendar.currentCalendarProducer,

            // track range from first activity information to current date
            currentAscendingBoundaryDate.producer.on(value: { result in
                if let error = result?.error
                {
                    errorLogFunction("Error loading ascending boundary date: \(error)")
                }
            }),
            currentDescendingBoundaryDate.producer,
            UIApplication.shared.significantDateProducer
        )

        let calendarBoundaryDatesResult = Property(
            initial: nil,
            then: boundsProducer.map({ calendar, optionalStartResult, _, _ in
                optionalStartResult.map({ startResult in
                    startResult.map({ optionalStart in
                        optionalStart.flatMap({ start in
                            CalendarBoundaryDates(
                                calendar: calendar,
                                fromMidnightBefore: start,
                                toMidnightAfter: Date()
                            )
                        })
                    })
                })
            })
        )

        self.calendarBoundaryDatesResult = calendarBoundaryDatesResult

        // create preloaded daily steps properties for step notifications
        currentDaySteps = ActivityTrackingService.dayStepsProperty(
            calendarBoundaryDatesResultProducer: calendarBoundaryDatesResult.producer,
            boundaryDatesToQuery: { $0.dayBoundaryDates.last },
            stepsProducer: { dates in
                healthKitService.healthKitStepsIfAvailableProducer(
                    fallbackDataSource: backupStepsDataSource,
                    makeProducer: {
                        $0.stepsProducer(startDate: dates.start, endDate: dates.end)
                    }
                )
            }
        )
    }

    // MARK: - HealthKit

    /// If HealthKit is available, the HealthKit service. Otherwise, `nil`.
    ///
    /// HealthKit is currently not available on iPad.
    fileprivate let healthKitService: HealthKitService?

    /// `true` if HealthKit is available.
    public var healthKitAvailable: Bool
    {
        return healthKitService != nil
    }

    /// Requests HealthKit authorization if available. Otherwise, returns a producer that immediately errors.
    public func requestHealthKitAuthorizationProducer() -> SignalProducer<(), NSError>
    {
        return healthKitService?.requestAuthorizationProducer()
            ?? SignalProducer(error: HealthKitUnsupportedError() as NSError)
    }

    /// The Health Store for this service, if available.
    public var healthStore: HKHealthStore?
    {
        return healthKitService?.healthStore
    }

    /// The steps sample type.
    public var stepsType: HKQuantityType?
    {
        return healthKitService?.stepsType
    }
    
    /// The mindful minute sample type.
    public var mindfulType: HKCategoryType?
    {
        return healthKitService?.mindfulType
    }

    /// A property for the HealthKit authorization status. If HealthKit is unavailable, this property will yield
    /// `.SharingDenied`.
    public let healthKitAuthorization: Property<HKAuthorizationStatus>

    // MARK: - Realm

    /// The Realm service, if available.
    public var realmService: RealmService?
    {
        return backupStepsDataSource as? RealmService // used for a developer feature
    }

    // MARK: - Backup Sources

    /// The backup steps data source, which will be used if HealthKit is unavailable.
    let backupStepsDataSource: StepsDataSource & SourcedStepsDataSource
    
    let backupMindfulMinuteDataSource: MindfulMinuteDataSource

    // MARK: - Preloading Boundary Dates

    /// A property for storing the service's ascending boundary date, preloading it to improve interface speed.
    fileprivate let currentAscendingBoundaryDate: Property<Result<Date?, NSError>?>

    /// A property for storing the service's descending boundary date, preloading it to improve interface speed.
    fileprivate let currentDescendingBoundaryDate: Property<Result<Date?, NSError>?>

    /// A property storing the day boundary dates containing the service's activity range, up to the current day. This
    /// is preloaded to improve interface speed.
    public let calendarBoundaryDatesResult: Property<Result<CalendarBoundaryDates?, NSError>?>

    // MARK: - Preloading Current Day's Steps

    /// The current day and its step count, as loaded from the data source.
    public let currentDaySteps: Property<Result<DateSteps, NSError>?>
    
    public let (syncSignal, syncObserver) = Signal<ActivityTrackingManualReadTriggerSource, NoError>.pipe()
}

extension ActivityTrackingService
{
    // MARK: - Property Setup

    /// Creates a property for loading a boundary date.
    ///
    /// - parameter healthKitService:      The HealthKit service to use, if any.
    /// - parameter backupStepsDataSource: The backup data source to use, if HealthKit is unavailable.
    /// - parameter retryProducer:         A producer for retrying failed queries.
    /// - parameter ascending:             Which boundary date to look up.
    fileprivate static func dateProperty(healthKitService: HealthKitService?,
                                     backupStepsDataSource: StepsDataSource,
                                     retryProducer: SignalProducer<(), NoError>,
                                     ascending: Bool)
        -> Property<Result<Date?, NSError>?>
    {
        let producer = healthKitService.healthKitStepsIfAvailableProducer(
            fallbackDataSource: backupStepsDataSource,
            makeProducer: { $0.stepsBoundaryDateProducer(ascending: ascending) }
        )

        return Property(
            initial: nil,
            then: producer
                .resultify()
                .retryOnValue(from: retryProducer)
                .map({ $0 })
        )
    }

    
    fileprivate static func dayStepsProperty(
        calendarBoundaryDatesResultProducer: SignalProducer<Result<CalendarBoundaryDates?, NSError>?, NoError>,
        boundaryDatesToQuery: @escaping (CalendarBoundaryDates) -> BoundaryDates?,
        stepsProducer: @escaping (BoundaryDates) -> SignalProducer<Steps, NSError>)
        -> Property<Result<DateSteps, NSError>?>
    {
        return Property(
            initial: nil,
            then: calendarBoundaryDatesResultProducer
                .flatMap(.latest, transform: { optionalResult -> SignalProducer<Result<DateSteps, NSError>?, NoError> in
                    if let result = optionalResult
                    {
                        return result.analysis(
                            ifSuccess: { optionalDates in
                                if let calendar = optionalDates?.calendar,
                                       let dates = optionalDates.flatMap(boundaryDatesToQuery)
                                {
                                    let components = calendar.dateComponents([.era, .year, .month, .day], from: dates.start)

                                    let currentDayStepsProducer = stepsProducer(dates).map({ steps in
                                        DateSteps(components: components, steps: steps)
                                    })

                                    return currentDayStepsProducer.resultify().map({ $0 })
                                }
                                else
                                {
                                    return SignalProducer(value: nil)
                                }
                            },
                            ifFailure: { SignalProducer(value: .failure($0)) }
                        )
                    }
                    else
                    {
                        return SignalProducer(value: nil)
                    }
                })
        )
    }
}

extension ActivityTrackingService: MindfulMinuteDataSource
{
    // MARK: - Activity Tracking Steps Data Source
    public func mindfulMinutesDataProducer(startDate: Date, endDate: Date) -> SignalProducer<MindfulMinuteData, NSError>
    {
        if let healthKitService = healthKitService {
            return healthKitService.healthKitMindfulIfAvailableProducer(
                fallbackDataSource: backupMindfulMinuteDataSource,
                makeProducer: { $0.mindfulMinutesDataProducer(startDate: startDate, endDate: endDate) }
                )
        } else {
            return SignalProducer.empty
        }
    }
}

extension ActivityTrackingService: StepsDataSource
{
    public func stepsBoundaryDateProducer(ascending: Bool, startDate: Date, endDate: Date) -> SignalProducer<Date?, NSError> {
        return healthKitService.healthKitStepsIfAvailableProducer(
            fallbackDataSource: backupStepsDataSource,
            makeProducer: { $0.stepsBoundaryDateProducer(ascending: ascending, startDate: startDate, endDate: endDate) }
        )
    }

    // MARK: - Activity Tracking Steps Data Source
    public func stepsDataProducer(startDate: Date, endDate: Date) -> SignalProducer<StepsData, NSError>
    {
        return healthKitService.healthKitStepsIfAvailableProducer(
            fallbackDataSource: backupStepsDataSource,
            makeProducer: { $0.stepsDataProducer(startDate: startDate, endDate: endDate) }
        )
    }

    public func stepsBoundaryDateProducer(ascending: Bool) -> SignalProducer<Date?, NSError>
    {
        func unresult(_ producer: SignalProducer<Result<Date?, NSError>?, NoError>) -> SignalProducer<Date?, NSError>
        {
            return producer
                .promoteErrors(NSError.self)
                .flatMapOptional(.latest, transform: SignalProducer.init)
                .map(flattenOptional)
        }

        return ascending
            ? unresult(currentAscendingBoundaryDate.producer)
            : unresult(currentDescendingBoundaryDate.producer)
    }
}

extension ActivityTrackingService: SourcedStepsDataSource
{
    public func stepsBoundaryDateProducer(ascending: Bool, sourceMACAddress: Int64)
        -> SignalProducer<Date?, NSError>
    {
        return backupStepsDataSource.stepsBoundaryDateProducer(ascending: ascending, sourceMACAddress: sourceMACAddress)
    }

    public func stepsDataProducer(startDate: Date, endDate: Date, sourceMACAddress: Int64)
        -> SignalProducer<StepsData, NSError>
    {
        return backupStepsDataSource.stepsDataProducer(
            startDate: startDate,
            endDate: endDate,
            sourceMACAddress: sourceMACAddress
        )
    }
}

public struct HealthKitUnsupportedError: CustomNSError
{
    public let errorCode = 0
    public static let errorDomain = "RinglyActivityTracking.HealthKitUnsupportedError"
}

extension HealthKitUnsupportedError: LocalizedError
{
    public var errorDescription: String?
    {
        return "HealthKit Unsupported"
    }

    public var failureReason: String?
    {
        return "HealthKit is not supported on this device."
    }
}

extension HealthKitService
{
    /**
     A producer that prefers HealthKit data if available, but falls back on an alternative producer.

     - parameter fallbackDataSource: A fallback data source to use if HealthKit data is not available.
     - parameter makeProducer:       A function to create a producer, given a steps data source.
     */
    fileprivate func healthKitStepsIfAvailableProducer<Value, Error>
        (fallbackDataSource: StepsDataSource,
         makeProducer: @escaping (StepsDataSource) -> SignalProducer<Value, Error>)
        -> SignalProducer<Value, Error>
    {
        let fallbackProducer = makeProducer(fallbackDataSource)

        return authorizationStatus.producer.flatMap(.latest, transform: { status in
            status == .sharingAuthorized
                ? makeProducer(self)
                : fallbackProducer
        })
    }
    
    fileprivate func healthKitMindfulIfAvailableProducer<Value, Error>
        (fallbackDataSource: MindfulMinuteDataSource,
         makeProducer: @escaping (MindfulMinuteDataSource) -> SignalProducer<Value, Error>)
        -> SignalProducer<Value, Error>
    {
        let fallbackProducer = makeProducer(fallbackDataSource)
        
        return authorizationStatus.producer.flatMap(.latest, transform: { status in
            status == .sharingAuthorized
                ? makeProducer(self)
                : fallbackProducer
        })
    }
}

extension OptionalProtocol where Wrapped == HealthKitService
{
    /**
     A producer that prefers HealthKit data if available, but falls back on an alternative producer.

     - parameter fallbackDataSource: A fallback data source to use if HealthKit data is not available.
     - parameter makeProducer:       A function to create a producer, given a steps data source.
     */
    fileprivate func healthKitStepsIfAvailableProducer<Value, Error>
        (fallbackDataSource: StepsDataSource,
         makeProducer: @escaping (StepsDataSource) -> SignalProducer<Value, Error>)
        -> SignalProducer<Value, Error>
    {
        return optional?.healthKitStepsIfAvailableProducer(fallbackDataSource: fallbackDataSource, makeProducer: makeProducer)
            ?? makeProducer(fallbackDataSource)
    }
    
    fileprivate func healthKitMindfulIfAvailableProducer<Value, Error>
        (fallbackDataSource: MindfulMinuteDataSource,
         makeProducer: @escaping (MindfulMinuteDataSource) -> SignalProducer<Value, Error>)
        -> SignalProducer<Value, Error>
    {
        return optional?.healthKitMindfulIfAvailableProducer(fallbackDataSource: fallbackDataSource, makeProducer: makeProducer)
            ?? makeProducer(fallbackDataSource)
    }
}

public enum ActivityTrackingManualReadTriggerSource: CustomStringConvertible, Equatable
{
    case foreground
    case pullToRefresh
    case dev
    
    public var description: String {
        switch self {
        case .foreground:
            return "Foreground"
        case .pullToRefresh:
            return "Pull To Refresh"
        case .dev:
            return "Dev"
        }
    }
}


public func ==(lhs: ActivityTrackingManualReadTriggerSource, rhs: ActivityTrackingManualReadTriggerSource) -> Bool {
    switch (lhs, rhs)
    {
    case (.foreground, .foreground):
        return true
    case (.pullToRefresh, .pullToRefresh):
        return true
    case (.dev, .dev):
        return true
    default:
        return false
    }
}
