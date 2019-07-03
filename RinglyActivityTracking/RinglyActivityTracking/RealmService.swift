import Foundation
import HealthKit
import ReactiveSwift
import RealmSwift
import Result
import RinglyExtensions
import RinglyKit

/// Provides an activity data store using a Realm database.
public final class RealmService
{
    // MARK: - Initialization

    /**
     Initializes a Realm service.

     - parameter fileURL:         The file URL for the Realm database.
     - parameter logFunction:     A function to use for logging.
     */
    public convenience init(fileURL: URL, logFunction: ((String) -> ())?)
    {
        let configuration = RealmService.configuration(fileURL: fileURL, logFunction: logFunction)
        self.init(configuration: configuration, logFunction: logFunction)
    }

    /**
     Initializes a Realm service.

     - parameter configuration:   The Realm configuration.
     - parameter logFunction:     A function to use for logging.
     */
    init(configuration: Realm.Configuration, logFunction: ((String) -> ())?)
    {
        let queueName = (configuration.fileURL?.path).map({ path in "Realm \(path)" }) ?? "Realm"

        self.configuration = configuration
        self.queue = DispatchQueue(label: queueName)
        self.logFunction = logFunction
    }

    // MARK: - Realm

    /// Creates a Realm configuration for the specified URL.
    ///
    /// - Parameter fileURL: The URL for the Realm database.
    static func configuration(fileURL: URL, logFunction: ((String) -> ())?) -> Realm.Configuration
    {
        return Realm.Configuration(
            fileURL: fileURL,
            schemaVersion: 5,
            migrationBlock: { (migration: RealmSwift.Migration, oldSchemaVersion: UInt64) in
                // note that version 2 is the oldest version that was released to customers.
                if oldSchemaVersion < 4
                {
                    migration.enumerateObjects(ofType: "UpdateModel", { old, new in
                        guard let timestamp = old?["timestamp"] as? Int32 else {
                            logFunction?("Could not find “timestamp” of \(old) in migration")
                            return
                        }

                        guard let sourceHash = old?["sourceHash"] as? Int16 else {
                            logFunction?("Could not find “sourceHash” of \(old) in migration")
                            return
                        }

                        let macAddress = Int64(sourceHash)
                        new?["macAddress"] = macAddress
                        new?["identifier"] = UpdateModel.identifier(timestamp: timestamp, macAddress: macAddress)
                    })
                }
            },
            objectTypes: [HealthKitQueuedUpdateModel.self, UpdateModel.self,
                          UpdateMindfulnessSession.self, MindfulnessSession.self]
        )
    }

    /// The Realm configuration.
    fileprivate let configuration: Realm.Configuration

    /// The queue to perform Realm operations on.
    fileprivate let queue: DispatchQueue

    /// The file URL of the Realm database.
    public var fileURL: URL?
    {
        return configuration.fileURL
    }

    // MARK: - ReactiveCocoa

    // MARK: - Logging
    fileprivate let logFunction: ((String) -> ())?
}

extension RealmService: SourcedUpdatesSink
{
    public func writeSourcedUpdatesProducer(_ updatesProducer: SignalProducer<SourcedUpdate, NoError>)
        -> SignalProducer<(), NoError>
    {
        return updatesProducer
            // only include updates that have non-zero steps and are within a reasonable time interval
            .filter({ sourced in
                guard sourced.update.steps > 0 else {
                    return false
                }

                let date = sourced.update.date.date

                return abs(date.timeIntervalSinceNow) < 86400 * 30
            })

            // buffer to group writes into transactions
            .buffer(limit: 100, timeout: .seconds(5), on: QueueScheduler.main)

            // write the data to Realm, yielding the intervals that were written after completion
            .flatMap(.latest, transform: { [weak self] sourcedUpdates in
                self?.writeSourcedUpdatesWithLogging(sourcedUpdates) ?? SignalProducer.empty
            }).ignoreValues()
        
    }
}

extension RealmService
{
    // MARK: - Realm Producers

    /**
     Creates a signal producer for accessing the Realm database.

     - parameter startHandler: A signal producer start handler function.
     */
    fileprivate func realmProducer<Value>
        (_ startHandler: @escaping (Realm, Observer<Value, NSError>, CompositeDisposable) throws -> ())
        -> SignalProducer<Value, NSError>
    {
        return configuration.realmProducer(queue: queue, startHandler: startHandler)
    }

    /**
     Creates a signal producer for continuously reading a result from the Realm database.

     - parameter makeResults: A function to create a `Results` value, given a Realm database.
     */
    fileprivate func realmResultsProducer<Value>(makeResults: @escaping (Realm) -> Results<Value>)
        -> SignalProducer<Results<Value>, NSError>
    {
        return configuration.realmResultsProducer(makeResults: makeResults)
    }
}

extension RealmService
{
    // MARK: - Writing Updates

    /**
     Writes updates to the Realm database.

     - parameter sourcedUpdates: The updates to write.
     */
    fileprivate func writeSourcedUpdates(_ sourcedUpdates: [SourcedUpdate]) -> SignalProducer<(), NSError>
    {
        return realmProducer { realm, observer, disposable in
            let updateModels = sourcedUpdates.map(UpdateModel.init)
            
            //find all records between min and max updates
            let minMaxTimestamp:(UpdateModel, UpdateModel) -> Bool = { (a,b) in a.timestamp < b.timestamp }
            
            
            if let minTimestamp = updateModels.min(by: minMaxTimestamp)?.timestamp,
                let maxTimestamp = updateModels.max(by: minMaxTimestamp)?.timestamp {
                let predicate = NSPredicate(format: "timestamp >= %d AND timestamp <= %d", minTimestamp, maxTimestamp)
                

                let persistedUpdateModelsInRange = realm.objects(UpdateModel.self).filter(predicate)
                let newUpdateModels = updateModels.filter({ updateModel in
                    if let matchedUpdateModel = persistedUpdateModelsInRange.first(where: { $0.identifier == updateModel.identifier }) {
                        return matchedUpdateModel.stepCount < updateModel.stepCount
                    }

                    return true
                })
                
                let healthKitQueuedUpdates = newUpdateModels.healthKitTimestamps.map(HealthKitQueuedUpdateModel.init)
                
                try realm.write {
                    realm.add(newUpdateModels, update: true)
                    realm.add(healthKitQueuedUpdates, update: true)
                }
            }

            observer.sendCompleted()
        }
    }

    /**
     Writes updates to the Realm database, logging the result of the operation.

     - parameter sourcedUpdates: The updates to write.
     */
    public func writeSourcedUpdatesWithLogging(_ sourcedUpdates: [SourcedUpdate]) -> SignalProducer<(), NoError>
    {
        let logFunction = self.logFunction

        // don't write empty updates
        guard
            let first = sourcedUpdates.first?.update.date.minute,
            let last = sourcedUpdates.last?.update.date.minute
        else { return SignalProducer.empty }

        let count = sourcedUpdates.count
        let sources = Set(sourcedUpdates.lazy.map({ $0.macAddress }))

        return writeSourcedUpdates(sourcedUpdates)
            .on(failed: { error in
                logFunction?("Error writing \(count) updates from \(sources): \(error)")
            }, completed: {
                logFunction?("Wrote \(count) updates from \(sources), from minute \(first) to \(last)")
            })
            .resultify()
            .ignoreValues()
    }

    /// A producer that, when started, asynchronously enqueues all HealthKit data for a rewrite. The producer does not
    /// wait for the rewrite to complete before completing.
    public func rewriteAllHealthKitData() -> SignalProducer<(), NSError>
    {
        return realmProducer { realm, observer, disposable in
            let models = realm.objects(UpdateModel.self)
            let queuedUpdates = models.healthKitTimestamps.map(HealthKitQueuedUpdateModel.init)

            try realm.write {
                realm.add(queuedUpdates, update: true)
            }

            observer.sendCompleted()
        }
    }

    /// Deletes all data stored in the Realm service.
    public func deleteAllData() -> SignalProducer<(), NSError>
    {
        return realmProducer { realm, observer, disposable in
            try realm.write {
                realm.delete(realm.objects(UpdateModel.self))
                realm.delete(realm.objects(HealthKitQueuedUpdateModel.self))
                realm.delete(realm.objects(UpdateMindfulnessSession.self))
                realm.delete(realm.objects(MindfulnessSession.self))
            }

            observer.sendCompleted()
        }
    }
    
    public func startMindfulnessSession(mindfulnessType: MindfulnessType, description: String, initialCount:Int = 1) -> SignalProducer<MindfulnessSession?, NSError>
    {
    
        return realmProducer { realm, observer, disposable in
            let startTimestamp = try RLYActivityTrackingDate(date: Date())
            let mindfulnessSession = MindfulnessSession.init(startTimestamp: Int32(startTimestamp.minute), minuteCount: Int32(initialCount), type: mindfulnessType, description: description)
            let updateMindfulnessSession = UpdateMindfulnessSession.init(id: mindfulnessSession.id)
            
            try realm.write {
                realm.add(mindfulnessSession)
                realm.add(updateMindfulnessSession)
            }

            observer.send(value: mindfulnessSession)
            observer.sendCompleted()
        }
        
    }
    
    /// Adds a minute to a mindfulness session in the Realm database. Also updates the corresponding 
    /// HealthKit MindfulSession entry if Health is enabled.
    public func addMinuteToMindfulnessSession(sessionId:String, store:HKHealthStore?)
        -> SignalProducer<Void, NSError>
    {
        return realmProducer { realm, observer, disposable in
            if let session = realm.objects(MindfulnessSession.self).filter("id=%@", sessionId).first {
                try realm.write {
                    session.minuteCount = session.minuteCount + 1
                }

                if #available(iOS 10.0, *), let store = store {
                    let type = HKCategoryType.categoryType(forIdentifier: .mindfulSession)!
                    let sample = self.createMindfulSession(session: session)
                    if let UUIDString = sample.metadata?[HKMetadataKeyExternalUUID].flatMap({$0}) as? String {
                        let predicate = NSPredicate(
                            format: "%K.%K == %@", HKPredicateKeyPathMetadata, HKMetadataKeyExternalUUID, UUIDString
                        )
                        store.deleteObjects(of: type, predicate: predicate, withCompletion: { success, count, error in
                            if error == nil {
                                store.save(sample, withCompletion: { (succ, err) in
                                })
                            }
                            observer.completionHandler(success: success, error: error)
                        })
                    }
                }
            }
            
            if let updateSession = realm.objects(UpdateMindfulnessSession.self).filter("id=%@", sessionId).first {
                try realm.write { realm.delete(updateSession) }
            }
            
            observer.sendCompleted()
        }
    }
    
    /// For first time with MindfulMinute integration, write all existing MindfulnessSession entries
    /// into the UpdateMindfulnessSession Realm object to be written to HealthKit.
    public func performMindfulnessMigration()
        -> SignalProducer<(), NSError>
    {
        return realmProducer { realm, observer, disposable in
            guard let results = try? realm.objects(MindfulnessSession.self) else { return }

            try results.forEach({ session in
                let updateSession = UpdateMindfulnessSession.init(id: session.id)
                try realm.write {
                    realm.add(updateSession, update: true)
                }
            })
            observer.sendCompleted()
        }
    }
    
    /// If any mindfulness objects have not been synced to Health, do so here and delete from the UpdateMindfulnessSession table.
    public func dequeueMindfulUpdate(store:HKHealthStore?)
        -> SignalProducer<(), NSError>
    {
        return realmProducer { realm, observer, disposable in
            guard let results = try? realm.objects(UpdateMindfulnessSession.self) else { return }
            guard let mindfulResults = try? realm.objects(MindfulnessSession.self) else { return }
            
            if #available(iOS 10.0, *), let store = store {
                try results.forEach({ session in
                    let mindfulSession = mindfulResults.filter("id=%@", session.id).first

                    if let mindfulSession = mindfulSession, mindfulSession.minuteCount > 0 {
                        let mindfulSession = self.createMindfulSession(session: mindfulSession)
                        
                        store.save(mindfulSession, withCompletion: { (succ, err) in })
                    }
                    
                    let predicate = NSPredicate(format: "id == %@", session.id)
                    try realm.write {
                        realm.delete(realm.objects(UpdateMindfulnessSession).filter(predicate))
                    }
                })
            }
        }
    }
    
    @available(iOS 10.0, *)
    fileprivate func createMindfulSession(session:MindfulnessSession)
        -> HKCategorySample
    {
        let type = HKCategoryType.categoryType(forIdentifier: .mindfulSession)!
        let date = Date(mindfulHealthKitTimeValue: session.startTimestamp)
        let sample = HKCategorySample(
            type: type,
            value: HKCategoryValue.notApplicable.rawValue,
            start: date,
            end: date.addingTimeInterval(Double(session.minuteCount) * 60.0),
            device: nil,
            metadata: [
                HKMetadataKeyExternalUUID: session.id,
                HKCategorySample.ringlyMindfulMinuteUserInfoKey: Int(session.minuteCount),
                HKCategorySample.ringlyMeditationUserInfoKey: session.mindfulnessDescription
            ]
        )
        return sample
    }
}

extension RealmService
{
    fileprivate func stepsBoundaryDateProducer(ascending: Bool, predicate: NSPredicate?)
         -> SignalProducer<Date?, NSError>
    {
        let updatesProducer = realmResultsProducer { realm -> Results<UpdateModel> in
            let results = realm.objects(UpdateModel.self)
            
            guard let predicate = predicate else {
                return results
            }
            
            return results.filter(predicate)
        }

        return updatesProducer.map({ updates in
            return (ascending ? updates.min : updates.max)("timestamp").map({ (timestamp: Int) in
                RLYActivityTrackingMinuteToNSDate(RLYActivityTrackingMinute(timestamp))
            })
        }).flatMapError({ _ in SignalProducer.empty })
    }

    func stepsDataProducer(startMinute: RLYActivityTrackingMinute,
                           endMinute: RLYActivityTrackingMinute,
                           predicate: NSPredicate?)
        -> SignalProducer<StepsData, NSError>
    {
        // create a predicate for the date range
        var predicates = [
            NSPredicate(format: "timestamp >= %d", startMinute),
            NSPredicate(format: "timestamp < %d", endMinute)
        ]

        if let p = predicate
        {
            predicates.append(p)
        }

        let fullPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        // perform the fetch request, reducing to a sum
        let updatesProducer = realmResultsProducer { realm -> Results<UpdateModel> in
            realm.objects(UpdateModel.self)
                .filter(fullPredicate)
                .sorted(byKeyPath: "timestamp", ascending: true)
        }

        return updatesProducer.map({ Steps.distinctMaxByMinuteSteps(timestampGroupedSteps: $0) })
    }

    fileprivate func stepsDataProducer(startDate: Date, endDate: Date, predicate: NSPredicate?)
        -> SignalProducer<StepsData, NSError>
    {
        do
        {
            return try stepsDataProducer(
                startMinute: RLYActivityTrackingDate(date: startDate).minute,
                endMinute: RLYActivityTrackingDate(date: endDate).minute,
                predicate: predicate
            )
        }
        catch let error as NSError
        {
            return SignalProducer(error: error)
        }
    }
}

extension RealmService: StepsDataSource
{
    public func stepsBoundaryDateProducer(ascending: Bool, startDate: Date, endDate: Date) -> SignalProducer<Date?, NSError> {
        var predicate = NSPredicate?.none
        do {
            let startMinute = try RLYActivityTrackingDate(date: startDate).minute
            let endMinute = try RLYActivityTrackingDate(date: endDate).minute
            predicate = NSPredicate(format: "timestamp >= %d AND timestamp <= %d", startMinute, endMinute)
        } catch let error as NSError {
            return SignalProducer(value: Date?.none)
        }

       return stepsBoundaryDateProducer(ascending: ascending, predicate: predicate)
    }

    // MARK: - Steps Data Source
    public func stepsBoundaryDateProducer(ascending: Bool) -> SignalProducer<Date?, NSError>
    {
        return stepsBoundaryDateProducer(ascending: ascending, predicate: nil)
    }

    public func stepsDataProducer(startDate: Date, endDate: Date)
        -> SignalProducer<StepsData, NSError>
    {
        return stepsDataProducer(startDate: startDate, endDate: endDate, predicate: nil)
    }
}

extension RealmService: SourcedStepsDataSource
{
    public func stepsBoundaryDateProducer(ascending: Bool, sourceMACAddress: Int64)
        -> SignalProducer<Date?, NSError>
    {
        let predicate = NSPredicate(format: "macAddress == %lld", sourceMACAddress)
        return stepsBoundaryDateProducer(ascending: ascending, predicate: predicate)
    }

    public func stepsDataProducer(startDate: Date, endDate: Date, sourceMACAddress: Int64)
        -> SignalProducer<StepsData, NSError>
    {
        return stepsDataProducer(
            startDate: startDate,
            endDate: endDate,
            predicate: NSPredicate(format: "macAddress == %lld", sourceMACAddress)
        )
    }
}

extension RealmService: MindfulMinuteDataSource
{
    public func mindfulMinutesDataProducer(startDate: Date, endDate: Date) -> SignalProducer<MindfulMinuteData, NSError>
    {
        var predicate = NSPredicate?.none
        do {
            let startMinute = try RLYActivityTrackingDate(date: startDate).minute
            let endMinute = try RLYActivityTrackingDate(date: endDate).minute
            predicate = NSPredicate(format: "startTimestamp >= %d AND startTimestamp <= %d", startMinute, endMinute)
        } catch let error as NSError {
            return SignalProducer.empty
        }
        
        guard let minutesPredicate = predicate else { return SignalProducer.empty }
        
        let results = configuration.realmResultsProducer { realm -> Results<MindfulnessSession> in
            realm.objects(MindfulnessSession.self).filter(minutesPredicate)
        }
        
        return results.map({ result in
            MindfulMinute(minuteCount: result.sum(ofProperty: "minuteCount"))
        })
    }
}

extension RealmService: HealthKitQueuedUpdatesDataSource
{
    public func queuedUpdatesTimeValuesProducer() -> SignalProducer<[Int32], NSError> {
        let producer: SignalProducer<[Int32], NSError> =
        realmProducer { (realm, observer, disposable) in
            observer.send(value: realm.objects(HealthKitQueuedUpdateModel.self).map({ $0.timeValue }))
        }
        
        return producer
    }
    
    public func autoUpdatingQueuedUpdatesTimeValuesProducer() -> SignalProducer<[Int32], NSError>
    {
        let resultsProducer = realmResultsProducer { realm -> Results<HealthKitQueuedUpdateModel> in
            realm.objects(HealthKitQueuedUpdateModel.self)
        }

        return resultsProducer.map({ models in models.map({ $0.timeValue }) })
    }

    public func fulfillQueuedUpdatesTimeValuesProducer(_ timeValues: [Int32]) -> SignalProducer<(), NSError>
    {
        return realmProducer { realm, observer, disposable in
            let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: timeValues.map({ timeValue in
                NSPredicate(format: "timeValue == %d", timeValue)
            }))

            try realm.write {
                realm.delete(realm.objects(HealthKitQueuedUpdateModel.self).filter(predicate))
            }

            observer.sendCompleted()
        }
    }

    public static func boundaryDatesForTimeValue(_ timeValue: Int32) -> BoundaryDates
    {
        return BoundaryDates(
            start: Date(healthKitTimeValue: timeValue),
            end: Date(healthKitTimeValue: timeValue + 1)
        )
    }

    public static func UUIDForTimeValue(_ timeValue: Int32) -> UUID
    {
        let unsigned = UInt32(bitPattern: timeValue)

        let bytes = [
            UInt8(truncatingBitPattern: unsigned),
            UInt8(truncatingBitPattern: unsigned >> 8),
            UInt8(truncatingBitPattern: unsigned >> 16),
            UInt8(truncatingBitPattern: unsigned >> 24),
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0, 0, 0
        ]

        return bytes.withUnsafeBufferPointer({ NSUUID(uuidBytes: $0.baseAddress) as UUID })
    }
}
