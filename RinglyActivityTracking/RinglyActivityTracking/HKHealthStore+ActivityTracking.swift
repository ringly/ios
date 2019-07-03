import Foundation
import HealthKit
import ReactiveSwift
import RinglyExtensions
import enum Result.NoError

public var HKHealthStoreDebugLogFunction: ((String) -> ())?

// MARK: - HealthKit Service Authorization Source

/// `HKHealthStore` is extended to conform to `HealthKitAuthorizationSource`.
extension HKHealthStore: HealthKitAuthorizationSource
{
    /**
     A signal producer for requesting HealthKit permissions. See Apple's documentation for `HKHealthStore` for more
     information.

     - parameter shareTypes: A set containing the data types to share.
     - parameter readTypes:  A set containing the data types to read.

     - returns: A signal producer that will complete on success, and fail on an error. Success does not imply that the
                user granted HealthKit permissions.
     */
    
    public func requestAuthorizationProducer(shareTypes: Set<HKSampleType>,
                                             readTypes: Set<HKObjectType>)
                                             -> SignalProducer<(), NSError>
    {
        precondition(readTypes.count > 0)

        return SignalProducer { observer, _ in
            self.requestAuthorization(toShare: shareTypes, read: readTypes, completion: { _, maybeError in
                if let error = maybeError
                {
                    observer.send(error: error as NSError)
                }
                else
                {
                    observer.sendCompleted()
                }
            })
        }
    }
}

// MARK: - HealthKit Service Query Source

/// `HKHealthStore` is extended to conform to `HealthKitQuerySource`.
extension HKHealthStore: HealthKitQuerySource
{
    /// A signal producer for a HealthKit query. See Apple's documentation for `HKSampleQuery` for argument information.
    
    public func queryProducer(sampleType: HKSampleType,
                              predicate: NSPredicate?,
                              limit: Int,
                              sortDescriptors: [NSSortDescriptor]?)
                              -> SignalProducer<[HKSample], NSError>
    {
        return SignalProducer { observer, disposable in
            let predicateString = predicate?.description ?? "null"

            if !UIApplication.shared.isProtectedDataAvailable
            {
                HKHealthStoreDebugLogFunction?("Starting sample query, predicate “\(predicateString)”, protected data unavailable!")
            }

            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: sortDescriptors,
                resultsHandler: { _, maybeSample, maybeError in
                    if let error = maybeError
                    {
                        HKHealthStoreDebugLogFunction?("Sample query failed, predicate “\(predicateString)”, protected data \(UIApplication.shared.isProtectedDataAvailable), error “\(error)”")
                        observer.send(error: HealthKitQueryError(underlyingHealthKitError: error as NSError) as NSError)
                    }
                    else
                    {
                        observer.send(value: maybeSample ?? [])
                        observer.sendCompleted()
                    }
                }
            )

            disposable += ActionDisposable { self.stop(query) }

            self.execute(query)
        }.deferUntilProtectedDataIsAvailable()
    }

    public func statisticsQueryProducer(quantityType: HKQuantityType,
                                        predicate: NSPredicate,
                                        options: HKStatisticsOptions)
                                        -> SignalProducer<HKStatistics, NSError>
    {
        return SignalProducer { observer, disposable in
            if !UIApplication.shared.isProtectedDataAvailable
            {
                HKHealthStoreDebugLogFunction?("Starting statistics query, predicate “\(predicate)”, protected data unavailable!")
            }

            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: options,
                completionHandler: { _, maybeStatistics, maybeError in
                    if let error = maybeError
                    {
                        HKHealthStoreDebugLogFunction?("Statistics query failed, predicate “\(predicate)”, protected data \(UIApplication.shared.isProtectedDataAvailable), error “\(error)”")
                        observer.send(error: HealthKitQueryError(underlyingHealthKitError: error as NSError) as NSError)
                    }
                    else
                    {
                        if let statistics = maybeStatistics
                        {
                            observer.send(value: statistics)
                        }

                        observer.sendCompleted()
                    }
                }
            )

            disposable += ActionDisposable { self.stop(query) }

            self.execute(query)
        }.deferUntilProtectedDataIsAvailable()
    }

    /// A signal producer for a HealthKit observer query. See Apple's documentation for `HKSampleQuery` for argument
    /// information.
    
    public func observerQueryProducer(sampleType: HKSampleType, predicate: NSPredicate?)
        -> SignalProducer<HKObserverQueryCompletionHandler, NSError>
    {
        return SignalProducer { observer, disposable in
            let predicateString = predicate?.description ?? "null"

            if !UIApplication.shared.isProtectedDataAvailable
            {
                HKHealthStoreDebugLogFunction?("Starting observer query, predicate “\(predicateString)”, protected data unavailable!")
            }

            let query = HKObserverQuery(
                sampleType: sampleType,
                predicate: predicate,
                updateHandler: { _, completion, maybeError in
                    if let error = maybeError
                    {
                        HKHealthStoreDebugLogFunction?("Observer query failed, predicate “\(predicateString)”, protected data \(UIApplication.shared.isProtectedDataAvailable), error “\(error)”")
                        observer.send(error: HealthKitObserverQueryError(underlyingHealthKitError: error as NSError) as NSError)
                        completion()
                    }
                    else
                    {
                        let predicateString = predicate?.description ?? "null"

                        if !UIApplication.shared.isProtectedDataAvailable
                        {
                            HKHealthStoreDebugLogFunction?("Observer query fired, predicate “\(predicateString)”, protected data unavailable!")
                        }

                        observer.send(value: completion)
                    }
                }
            )

            disposable += ActionDisposable { self.stop(query) }

            self.execute(query)
        }.deferUntilProtectedDataIsAvailable()
    }
}

// MARK: - HealthKit Save Sink
extension HKHealthStore: HealthKitSaveSink
{
    public func saveObjectsProducer(_ objects: [HKObject]) -> SignalProducer<(), NSError>
    {
        return SignalProducer { observer, _ in
            self.save(objects, withCompletion: observer.completionHandler)
        }
    }

    fileprivate func deleteObjectProducer(UUIDString: String, type: HKObjectType) -> SignalProducer<(), NSError>
    {
        return SignalProducer { observer, _ in
            let predicate = NSPredicate(
                format: "%K.%K == %@", HKPredicateKeyPathMetadata, HKMetadataKeyExternalUUID, UUIDString
            )

            self.deleteObjects(of: type, predicate: predicate, withCompletion: { success, count, error in
                observer.completionHandler(success: success, error: error)
            })
        }
    }

    public func deleteObjectsProducer(UUIDStrings: [String], type: HKObjectType) -> SignalProducer<(), NSError>
    {
        return SignalProducer.concat(UUIDStrings.map({ deleteObjectProducer(UUIDString: $0, type: type) }))
    }

    public var stepsAuthorizationStatusProducer: SignalProducer<HKAuthorizationStatus, NoError>
    {
        let notifications = NotificationCenter.default.reactive
            .notifications(forName: NSNotification.Name.UIApplicationWillEnterForeground, object: UIApplication.shared)

        return HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount).map({ type in
            SignalProducer(notifications)
                .initializeAndReplaceFuture({ self.authorizationStatus(for: type) })
                .skipRepeats()
        }) ?? SignalProducer(value: .sharingDenied)
    }
    
    public var mindfulMinuteAuthorizationStatusProducer: SignalProducer<HKAuthorizationStatus, NoError>
    {
        let notifications = NotificationCenter.default.reactive
            .notifications(forName: NSNotification.Name.UIApplicationWillEnterForeground, object: UIApplication.shared)
        
        if #available(iOS 10.0, *) {
            return HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.mindfulSession).map({ type in
                SignalProducer(notifications)
                    .initializeAndReplaceFuture({ self.authorizationStatus(for: type) })
                    .skipRepeats()
            }) ?? SignalProducer(value: .sharingDenied)
        } else {
            return SignalProducer(value: .notDetermined)
        }
    }
}

// MARK: - Errors

/// An error that wraps HealthKit query errors to add additional context.
public struct HealthKitQueryError: Error
{
    /// The underlying error for this error.
    let underlyingHealthKitError: NSError
}

extension HealthKitQueryError: CustomNSError
{
    /// The domain for these errors is `RinglyActivityTracking.HealthKitQueryError`.
    public static let errorDomain = "RinglyActivityTracking.HealthKitQueryError"

    /// The error code for these errors is `0`.
    public var errorCode: Int { return 0 }
}

extension HealthKitQueryError: LocalizedError
{
    public var errorDescription: String? { return "Health Query Error" }
    public var failureReason: String? { return underlyingHealthKitError.localizedDescription }
    public var underlyingError: NSError? { return underlyingHealthKitError }
}

/// An error that wraps HealthKit observer query errors to add additional context.
public struct HealthKitObserverQueryError: Error
{
    /// The underlying error for this error.
    let underlyingHealthKitError: NSError
}

extension HealthKitObserverQueryError: CustomNSError
{
    /// The domain for these errors is `RinglyActivityTracking.HealthKitObserverQueryError`.
    public static let errorDomain = "RinglyActivityTracking.HealthKitObserverQueryError"

    /// The error code for these errors is `0`.
    public var errorCode: Int { return 0 }
}

extension HealthKitObserverQueryError: LocalizedError
{
    public var errorDescription: String? { return "Health Observer Query Error" }
    public var failureReason: String? { return underlyingHealthKitError.localizedDescription }
    public var underlyingError: NSError? { return underlyingHealthKitError }
}
