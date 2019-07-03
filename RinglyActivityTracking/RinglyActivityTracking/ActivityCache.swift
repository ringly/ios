import RealmSwift
import ReactiveSwift
import enum Result.NoError

/// Caches single value representations of activity tracking data for much quicker loading.
///
/// It is assumed that a single cache file represents a single unit of elapsed time (day, hour).
public final class ActivityCache
{
    /// Initializes an activity cache.
    ///
    /// - Parameter fileURL: The URL at which the cache file should be stored. This should be in a cache directory, so
    ///                      that iOS can delete the cache if file space is needed.
    public init(fileURL: URL?)
    {
        configuration = Realm.Configuration(
            fileURL: fileURL,
            schemaVersion: 1,
            deleteRealmIfMigrationNeeded: true,
            objectTypes: [ActivityCacheRecord.self, MindfulCacheRecord.self]
        )
    }

    /// The Realm configuration for the activity cache database.
    fileprivate let configuration: Realm.Configuration

    /// A producer for cached steps data.
    ///
    /// - Parameters:
    ///   - startDate: The start date to request cached data from.
    ///   - count: The number of days to request cached data for.
    /// - Returns: A producer that will yield an array of cached steps data of length `count`. If data is unavailable
    ///            for a specific index, that index will be populated with a zero value.
    public func stepsProducer(startDate: Date, count: Int) -> SignalProducer<[Steps], NSError>
    {
        let results = configuration.realmResultsProducer { realm -> Results<ActivityCacheRecord> in
            realm.objects(ActivityCacheRecord.self).filter(NSPredicate(startDate: startDate as Date))
        }

        return results.map({ results in
            var array = Array(repeating: Steps.zero, count: count)

            results.forEach({ record in
                let index = record.index

                if index < count
                {
                    array[index] = record.steps
                }
            })

            return array
        })
    }
    
    /// A producer for all cached steps data.

    public func stepsProducer() -> SignalProducer<[(Date,Steps)], NSError>
    {
        let results = configuration.realmResultsProducer { realm -> Results<ActivityCacheRecord> in
            realm.objects(ActivityCacheRecord.self)
        }
        
        do {
            let realm = try Realm(configuration: configuration)
            let results = realm.objects(ActivityCacheRecord.self)
            
            var array = Array(repeating: (Date.distantPast, Steps.zero), count: results.count)
            
            results.forEach({ record in
                if let startDate = record.startDate {
                    let date = startDate.addingTimeInterval(Double(record.index) * 86400.0)
                    array[record.index] =  (date, record.steps)
                }
            })
            
            return SignalProducer<[(Date,Steps)], NSError>(value: array)

        } catch {
            return SignalProducer<[(Date,Steps)], NSError>(value: [])
        }
    }
    
    /// A producer for cached mindful minute data.
    ///
    /// - Parameters:
    ///   - startDate: The start date to request cached data from.
    ///   - count: The number of days to request cached data for.
    /// - Returns: A producer that will yield an array of cached mindful minute data of length `count`. If data is unavailable
    ///            for a specific index, that index will be populated with a zero value.
    public func mindfulMinutesProducer(startDate: Date, count: Int) -> SignalProducer<[MindfulMinute], NSError>
    {
        let results = configuration.realmResultsProducer { realm -> Results<MindfulCacheRecord> in
            realm.objects(MindfulCacheRecord.self).filter(NSPredicate(startDate: startDate as Date))
        }
        
        return results.map({ results in
            var array = Array(repeating: MindfulMinute.zero, count: count)
            
            results.forEach({ record in
                let index = record.index
                
                if index < count
                {
                    array[index] = record.minutes
                }
            })
            
            return array
        })
    }
    
    /// Writes data to the cache.
    ///
    /// - Parameters:
    ///   - startDate: The start date for the data.
    ///   - index: The index for the data (the number of calendar units elapsed since `startDate`).
    ///   - steps: The steps data to write.
    @discardableResult
    public func write(startDate: Date, index: Int, steps: Steps) -> Disposable
    {
        let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)
        let predicate = NSCompoundPredicate(startDate: startDate, index: index)

        let producer: SignalProducer<(), NSError> =
            configuration.realmProducer(queue: queue) { realm, observer, disposable in
                try realm.write {
                    realm.delete(realm.objects(ActivityCacheRecord.self).filter(predicate))

                    let record = ActivityCacheRecord()
                    record.startDate = startDate
                    record.index = index
                    record.walkingStepCount = steps.walkingStepCount
                    record.runningStepCount = steps.runningStepCount
                    realm.add(record)
                }

                observer.sendCompleted()
            }

        return producer.startWithFailed({ error in
            print(error)
        })
    }
    
    @discardableResult
    public func write(startDate: Date, index: Int, mindfulMinutes: MindfulMinute) -> Disposable
    {
        let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)
        let predicate = NSCompoundPredicate(startDate: startDate, index: index)
        
        let producer: SignalProducer<(), NSError> =
            configuration.realmProducer(queue: queue) { realm, observer, disposable in
                try realm.write {
                    realm.delete(realm.objects(MindfulCacheRecord.self).filter(predicate))
                    
                    let record = MindfulCacheRecord()
                    record.startDate = startDate
                    record.index = index
                    record.minuteCount = mindfulMinutes.minuteCount
                    realm.add(record)
                }
                
                observer.sendCompleted()
        }
        
        return producer.startWithFailed({ error in
            print(error)
        })
    }
}

internal final class ActivityCacheRecord: Object, StepsData
{
    // MARK: - Dates
    dynamic var startDate: Date?
    dynamic var index: Int = 0

    // MARK: - Step Counts
    dynamic var walkingStepCount: Int = 0
    dynamic var runningStepCount: Int = 0
}

internal final class MindfulCacheRecord: Object, MindfulMinuteData
{
    // MARK: - Dates
    dynamic var startDate: Date?
    dynamic var index: Int = 0
    
    dynamic var minuteCount: Int = 0
}

extension NSPredicate
{
    @nonobjc fileprivate convenience init(startDate: Date)
    {
        self.init(format: "startDate == %@", startDate as NSDate)
    }
}

extension NSCompoundPredicate
{
    @nonobjc fileprivate convenience init(startDate: Date, index: Int)
    {
        self.init(andPredicateWithSubpredicates: [
            NSPredicate(startDate: startDate),
            NSPredicate(format: "index == %d", index)
        ])
    }
}
