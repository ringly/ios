import Foundation
import HealthKit
import ReactiveSwift
import Realm
import enum Result.NoError
import struct RinglyExtensions.UnknownError

public protocol HealthKitQueuedUpdatesDataSource: class
{
    /// A onetime producer for a set of queued update items
    func queuedUpdatesTimeValuesProducer() -> SignalProducer<[Int32], NSError>
    
    /// An autoupdating producer for a set of queued update times.
    func autoUpdatingQueuedUpdatesTimeValuesProducer() -> SignalProducer<[Int32], NSError>

    /**
     A producer that will fulfill the specified queued update times.

     - parameter timeValues: The time values to fulfill.
     */
    func fulfillQueuedUpdatesTimeValuesProducer(_ timeValues: [Int32]) -> SignalProducer<(), NSError>

    /**
     Yields the boundary dates for a specific time value.

     - parameter timeValue: The time value.
     */
    static func boundaryDatesForTimeValue(_ timeValue: Int32) -> BoundaryDates

    /**
     Yields a UUID for a specific time value.

     - parameter timeValue: The time value.
     */
    static func UUIDForTimeValue(_ timeValue: Int32) -> UUID
}

extension HealthKitQueuedUpdatesDataSource where Self: StepsDataSource
{
    
    /**
     A producer for a one-time query of healthkit queued updates to process them for writing to healthkit
    */
    public func clearHealthKitQueuedUpdates(to sink: HealthKitSaveSink, logFunction: @escaping (String) -> ()) -> SignalProducer<NSError, NSError>
    {
        // requirements for creating samples
        let type = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let unit = HKUnit.count()
        let queuedUpdatesProducer = self.queuedUpdatesTimeValuesProducer()
        
        return sink.stepsAuthorizationStatusProducer
            .flatMap(.latest, transform: { [weak self] status -> SignalProducer<NSError, NSError> in
                // only attempt to write if it is permitted by the user
                guard let strong = self, status == .sharingAuthorized else { return SignalProducer.empty }
                return strong.innerWriteProducer(
                    type: type,
                    unit: unit,
                    sink: sink,
                    queuedUpdatesProducer: queuedUpdatesProducer,
                    logFunction: logFunction
                )
            })
    }
    
    /**
     A producer for connecting the data source to a write sink.
     
     This producer will yield errors as values. These indicate an error with a single write operation, and can be
     logged, but future write operations will continue.
     
     If this producer sends an error event, that indicates a failure of the underlying subscription to to queued updates
     data source, and the producer will terminate.

     - parameter sink:        The write sink.
     - parameter logFunction: A function to provide logging support.
     */
    public func writeProducer(to sink: HealthKitSaveSink, logFunction: @escaping (String) -> ())
        -> SignalProducer<NSError, NSError>
    {
        // requirements for creating samples
        let type = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let unit = HKUnit.count()

        return sink.stepsAuthorizationStatusProducer
            .flatMap(.latest, transform: { [weak self] status -> SignalProducer<NSError, NSError> in
                // only attempt to write if it is permitted by the user
                guard let strong = self, status == .sharingAuthorized else { return SignalProducer.empty }
                return strong.innerWriteProducer(
                    type: type,
                    unit: unit,
                    sink: sink,
                    queuedUpdatesProducer: strong.autoUpdatingQueuedUpdatesTimeValuesProducer(),
                    logFunction: logFunction
                )
            })
    }


    /**
     An implementation detail of `writeProducer(to:)`.

     - parameter type:        The quantity type to use when writing.
     - parameter unit:        The unit to use when writing.
     - parameter logFunction: A function to provide logging support.
     */
    fileprivate func innerWriteProducer(type: HKQuantityType,
                                    unit: HKUnit,
                                    sink: HealthKitSaveSink,
                                    queuedUpdatesProducer: SignalProducer<[Int32], NSError>,
                                    logFunction: @escaping (String) -> ())
                                    -> SignalProducer<NSError, NSError>
    {
        return queuedUpdatesProducer
            .filter({ $0.count > 0 })
            .flatMap(.concat, transform: { [weak self] timeValues -> SignalProducer<NSError, NoError> in
                guard let strong = self else { return SignalProducer.empty }

                return strong.writeTimeValuesProducer(type: type,
                                                      unit: unit,
                                                      sink: sink,
                                                      timeValues: timeValues,
                                                      logFunction: logFunction)
                    // the producer yields `()`, so this is primarily for type conversion
                    .map({ _ in UnknownError() as NSError })

                    // lift failure events into next events
                    .flatMapError({ error -> SignalProducer<NSError, NoError> in SignalProducer(value: error) })
            })
    }
    
    

    /**
     A producer that will write the time values to the sink and fulfill them in

     - parameter type:        The quantity type to use when writing.
     - parameter unit:        The unit to use when writing.
     - parameter sink:        The sink to write to.
     - parameter timeValues:  The time values to write.
     - parameter logFunction: A function to provide logging support.
     */
    fileprivate func writeTimeValuesProducer(type: HKQuantityType,
                                         unit: HKUnit,
                                         sink: HealthKitSaveSink,
                                         timeValues: [Int32],
                                         logFunction: @escaping (String) -> ())
                                         -> SignalProducer<(), NSError>
    {
        // create an array of sample producers, one for each time value
        let sampleProducers = timeValues.map({ timeValue -> SignalProducer<HKQuantitySample, NSError> in
            self.quantitySampleProducer(type: type, unit: unit, timeValue: timeValue)
        })

        // combine the results of all samples, then save to the HealthKit sink
        // it is not necessary to .take(first: 1) here, as that is already done in all individual producers
        // we need to use flatten/collect here, because combineLatest and zip cause stack overflows
        let save = SignalProducer.concat(sampleProducers)
            .collect()
            .flatMap(.concat, transform: { samples -> SignalProducer<(), NSError> in
                sink.updateObjectsProducer(samples, type: type)
            })
            .on(completed: {
                logFunction("Successfully wrote time values \(timeValues) to HealthKit")
            })

        // after the HealthKit save completes, fulfill the time values in the data source
        return save.then(fulfillQueuedUpdatesTimeValuesProducer(timeValues))
    }

    /**
     A producer that yields a quantity sample for the specified time value.

     - parameter type:      The quantity type to use for the sample.
     - parameter unit:      The unit to use for the sample.
     - parameter timeValue: The time value.
     */
    fileprivate func quantitySampleProducer(type: HKQuantityType, unit: HKUnit, timeValue: Int32)
        -> SignalProducer<HKQuantitySample, NSError>
    {
        // request the steps
        let boundaryDates = Self.boundaryDatesForTimeValue(timeValue)

        return self.stepsProducer(startDate: boundaryDates.start, endDate: boundaryDates.end)
            .take(first: 1)
            .map({ steps in
                HKQuantitySample(
                    type: type,
                    quantity: HKQuantity(unit: unit, doubleValue: Double(steps.stepCount)),
                    start: boundaryDates.start,
                    end: boundaryDates.end,
                    device: nil,
                    metadata: [
                        HKMetadataKeyExternalUUID: Self.UUIDForTimeValue(timeValue).uuidString,
                        HKQuantitySample.ringlyWalkingStepsUserInfoKey: steps.walkingStepCount,
                        HKQuantitySample.ringlyRunningStepsUserInfoKey: steps.runningStepCount
                    ]
                )
            })
    }
}
