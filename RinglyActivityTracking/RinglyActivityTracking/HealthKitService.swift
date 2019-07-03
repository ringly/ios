import HealthKit
import ReactiveSwift
import Result
import RinglyExtensions

public final class HealthKitService
{
    // MARK: - Initialization for iOS 10.0 and above
    public init(authorizationSource: HealthKitAuthorizationSource,
                querySource: HealthKitQuerySource,
                stepsType: HKQuantityType,
                mindfulType: HKCategoryType)
    {
        // sources
        self.authorizationSource = authorizationSource
        self.querySource = querySource

        // sample types
        self.stepsType = stepsType
        self.mindfulType = mindfulType

        // triggers for re-requesting authorization
        let authorizationPipe = Signal<(), NoError>.pipe()
        self.authorizationPipe = authorizationPipe

        let triggers = Signal.merge(
            NotificationCenter.default.reactive
                .notifications(forName: NSNotification.Name.UIApplicationDidBecomeActive, object: UIApplication.shared)
                .map { _ in () },
            authorizationPipe.0
        )

        // bind the authorization status
        let authorizationStatusTypes = [stepsType, mindfulType]

        self.authorizationStatus = Property(
            initial: authorizationStatusTypes
                .map(authorizationSource.authorizationStatusForType)
                .mergedAuthorizationStatus,
            then: SignalProducer(triggers).map({ _ in
                authorizationStatusTypes
                    .map(authorizationSource.authorizationStatusForType)
                    .mergedAuthorizationStatus
            }).skipRepeats()
        )
    }
    
    // MARK: - Initialization
    public init(authorizationSource: HealthKitAuthorizationSource,
                querySource: HealthKitQuerySource,
                stepsType: HKQuantityType)
    {
        // sources
        self.authorizationSource = authorizationSource
        self.querySource = querySource
        
        // sample types
        self.stepsType = stepsType
        self.mindfulType = nil
        
        // triggers for re-requesting authorization
        let authorizationPipe = Signal<(), NoError>.pipe()
        self.authorizationPipe = authorizationPipe
        
        let triggers = Signal.merge(
            NotificationCenter.default.reactive
                .notifications(forName: NSNotification.Name.UIApplicationDidBecomeActive, object: UIApplication.shared)
                .map { _ in () },
            authorizationPipe.0
        )
        
        // bind the authorization status
        let authorizationStatusTypes = [stepsType]
        
        self.authorizationStatus = Property(
            initial: authorizationStatusTypes
                .map(authorizationSource.authorizationStatusForType)
                .mergedAuthorizationStatus,
            then: SignalProducer(triggers).map({ _ in
                authorizationStatusTypes
                    .map(authorizationSource.authorizationStatusForType)
                    .mergedAuthorizationStatus
            }).skipRepeats()
        )
    }

    // MARK: - Authorization

    /// A signal producer that will request authorization for the user. To ensure that the
    /// `authorizationStatusForWritingSteps` property is updated correctly, always use this
    /// producer, instead of directly accessing `HKHealthStore`.
    func requestAuthorizationProducer() -> SignalProducer<(), NSError>
    {
        var shareTypes: Set<HKSampleType>
        var readTypes: Set<HKSampleType>
        
        if let mindfulType = mindfulType, #available(iOS 10.0, *) {
            shareTypes = [stepsType, mindfulType]
            readTypes = [stepsType, mindfulType]
        }
        else {
            shareTypes = [stepsType]
            readTypes = [stepsType]
        }
        
        return authorizationSource.requestAuthorizationProducer(shareTypes: shareTypes, readTypes: readTypes)
            // when the producer completes, authorization status may have changed, so trigger a new query
            .on(completed: authorizationPipe.1.send)
    }

    /// A property describing whether or not the user has permitted the app to write data to HealthKit.
    let authorizationStatus: Property<HKAuthorizationStatus>

    /// A pipe for triggering an authorization reload after authentication is requested.
    fileprivate let authorizationPipe: (Signal<(), NoError>, Observer<(), NoError>)

    // MARK: - Sources

    /// The authorization source for the service.
    fileprivate let authorizationSource: HealthKitAuthorizationSource

    /// The query source for the service.
    fileprivate let querySource: HealthKitQuerySource

    /// The Health Store for this service, if available.
    var healthStore: HKHealthStore?
    {
        return querySource as? HKHealthStore
    }

    // MARK: - Sample Types

    /// The steps sample type.
    let stepsType: HKQuantityType
    
    /// The mindful minute sample type.
    let mindfulType: HKCategoryType?
    
    // Static variable for second delay to count as new 'minute'
    public static let secondDelay:Double = 10
}

extension HealthKitService
{
    // MARK: - Creating a Service

    /**
     Creates a service with the specified health store, if possible.

     - parameter healthStore: The health store.

     - returns: A result value. In practice, this should always be successful - the only requirement is that the sample
                types can be created, which they should be, as they're using HealthKit constants.
     */
    public static func with(healthStore: HKHealthStore)
        -> Result<HealthKitService, HealthKitServiceCreateError>
    {
        guard let stepsType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else {
            return .failure(.noStepsType)
        }
        
        if #available(iOS 10.0, *) {
            guard let mindfulType = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier.mindfulSession) else {
                return .failure(.noMindfulType)
            }
            
            return .success(HealthKitService(
                authorizationSource: healthStore,
                querySource: healthStore,
                stepsType: stepsType,
                mindfulType: mindfulType
            ))
        } else {
            return .success(HealthKitService(
                authorizationSource: healthStore,
                querySource: healthStore,
                stepsType: stepsType
            ))
        }

    }
}

extension HealthKitService
{
    // MARK: - HealthKit Producers

    /**
     A producer for an array of samples.

     This producer will automatically update whenever new data is available.

     - parameter sampleType: The sample type to request.
     - parameter startDate:  The start date for the query.
     - parameter endDate:    The end date for the query.
     - parameter ascending:  Whether or the date sort should be ascending.
     - parameter limit:      The limit for the query.
     */
    fileprivate func samplesProducer(sampleType: HKSampleType,
                                 startDate: Date,
                                 endDate: Date,
                                 ascending: Bool,
                                 limit: Int)
        -> SignalProducer<[HKSample], NSError>
    {
        let predicate = HKQuery.predicateForSamples(withStart: startDate as Date, end: endDate as Date, options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: ascending)

        return querySource.updatingQueryProducer(
            sampleType: sampleType,
            predicate: predicate,
            limit: limit,
            sortDescriptors: [sort]
        )
    }
}

extension HealthKitService: MindfulMinuteDataSource
{
    public func mindfulMinutesDataProducer(startDate: Date, endDate: Date) -> SignalProducer<MindfulMinuteData, NSError> {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictStartDate])
        
        let updating = endDate.timeIntervalSinceNow > -86400 * 4

        guard let mindfulType = mindfulType else { return SignalProducer.empty }
        
        let query = ( updating ? querySource.updatingQueryProducer : querySource.queryProducer)(
            mindfulType,
            predicate,
            HKObjectQueryNoLimit,
            [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        )
        
        let totalTime = TimeInterval(0)
        
        let minutesQuery = query.map({ ($0 as? [HKCategorySample]) ?? [] }).map({ samples in
            samples.reduce(TimeInterval(0), { current, sample in
                // add up all time intervals for each sample
                let timeElapsed = sample.endDate.timeIntervalSince(sample.startDate)
                return current + timeElapsed
            })
        })
        
        return minutesQuery.map({ time in
            // map time intervals to mindful minute type
            let minutes = Int(floor((time-HealthKitService.secondDelay)/60) + 1)
            return MindfulMinute(minuteCount: minutes)
        })
    }
}

extension HealthKitService: StepsDataSource
{
    public func stepsBoundaryDateProducer(ascending: Bool, startDate: Date, endDate: Date) -> SignalProducer<Date?, NSError> {
        return samplesProducer(
            sampleType: stepsType,
            startDate: startDate,
            endDate: endDate,
            ascending: ascending,
            limit: 1
            ).map({ samples in
                if ascending {
                    return samples.first?.startDate
                } else {
                    return samples.first?.endDate
                }
            })
    }

    
    // MARK: - Activity Tracking Steps Data Source
    public func stepsDataProducer(startDate: Date, endDate: Date) -> SignalProducer<StepsData, NSError>
    {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictStartDate])

        // this is a hack to work around a major issue in HealthKit, and to improve performance.
        // starting too many observer queries can cause HealthKit to stop recognizing steps data altogether, which
        // causes the app to freeze on launch until the phone is restarted. therefore, we only start observers for the
        // fast few days (roughly, which should be good enough).
        let updating = endDate.timeIntervalSinceNow > -86400 * 4

        let query = (updating ? querySource.updatingStatisticsQueryProducer : querySource.statisticsQueryProducer)(
            stepsType,
            predicate,
            .cumulativeSum
        )

        // a predicate for the samples within the original predicate that originate from the Ringly app and contain
        // a non-zero number of running steps.
        let runningPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicate,
            HKQuery.predicateForObjects(from: HKSource.default()),
            HKQuery.predicateForObjects(
                withMetadataKey: HKQuantitySample.ringlyRunningStepsUserInfoKey,
                operatorType: .greaterThan,
                value: 0
            )
        ])

        let runningSamplesQuery = (updating ? querySource.updatingQueryProducer : querySource.queryProducer)(
            stepsType,
            runningPredicate,
            HKObjectQueryNoLimit,
            nil
        )

        let runningStepsQuery = runningSamplesQuery
            .map({ ($0 as? [HKQuantitySample]) ?? [] })
            .map({ samples in
                samples.reduce(0, { current, sample in current + sample.runningStepCount })
            })

        return query.combineLatest(with: runningStepsQuery).map({ statistics, runningSteps in
            let value = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            return Steps(walkingStepCount: max(Int(value) - runningSteps, 0), runningStepCount: runningSteps)
        })
    }

    public func stepsBoundaryDateProducer(ascending: Bool) -> SignalProducer<Date?, NSError>
    {
        let calendar = Calendar.current
        let startBeforeEnd = calendar.startOfDay(for: Date())
        
        let endMidnight = calendar.date(byAdding: .day, value: 1, to: startBeforeEnd) ?? Date()
        
        return self.stepsBoundaryDateProducer(
            ascending: ascending,
            startDate: querySource.earliestPermittedSampleDate(),
            endDate: endMidnight
        )
    }
}

// MARK: - Create Error

/// Enumerates errors that can occur when creating a `HealthKitService` using `with`.
public enum HealthKitServiceCreateError: Error
{
    /// The steps sample type could not be created.
    case noStepsType
    
    /// The mindful minute type could not be created.
    case noMindfulType

    /// The calories sample type could not be created.
    case noCaloriesType

    /// The distance sample type could not be created.
    case noDistanceType

    /// The height sample type could not be created.
    case noHeightType

    /// The body mass sample type could not be created.
    case noBodyMassType

    /// The date-of-birth characteristic type could not be created.
    case noDateOfBirthType
}

extension Sequence where Iterator.Element == HKAuthorizationStatus
{
    /// Merges the authorization statuses for a sequence, preferring `NotDetermined` over `SharingDenied` over
    /// `SharingAuthorized`.
    fileprivate var mergedAuthorizationStatus: HKAuthorizationStatus
    {
        return reduce(HKAuthorizationStatus.sharingAuthorized, { current, next in
            // not determined status should override all other statuses
            if current == .notDetermined || next == .notDetermined
            {
                return .notDetermined
            }

            // denied status should override all other statuses
            if current == .sharingDenied || next == .sharingDenied
            {
                return .sharingDenied
            }

            return .sharingAuthorized
        })
    }
}
