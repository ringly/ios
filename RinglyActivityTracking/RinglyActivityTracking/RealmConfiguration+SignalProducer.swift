import RealmSwift
import ReactiveSwift

extension Realm.Configuration
{
    // MARK: - Realm Producers

    /**
     Creates a signal producer for accessing the Realm database.

     - parameter queue:        The dispatch queue to access Realm on.
     - parameter startHandler: A signal producer start handler function.
     */
    
    public func realmProducer<Value>
        (queue: DispatchQueue, startHandler: @escaping (Realm, Observer<Value, NSError>, CompositeDisposable) throws -> ())
        -> SignalProducer<Value, NSError>
    {
        return queue.producer { observer, disposable in
            do
            {
                try startHandler(Realm(configuration: self), observer, disposable)
            }
            catch let error as NSError
            {
                observer.send(error: error)
            }
        }
    }

    /**
     Creates a signal producer for continuously reading updates from the Realm database.

     - parameter makeResults: A function to create a `Results` value, given a Realm database.
     */
    
    public func realmUpdatesProducer<Value>(makeResults: @escaping (Realm) -> Results<Value>)
        -> SignalProducer<RealmCollectionChange<Results<Value>>, NSError>
    {
        return DispatchQueue.main.producer { observer, disposable in
            do
            {
                let realm = try Realm(configuration: self)
                let results = makeResults(realm)

                let token = results.addNotificationBlock(observer.send)
                disposable += ActionDisposable(action: token.stop)
            }
            catch let error as NSError
            {
                observer.send(error: error)
            }
        }
    }

    /**
     Creates a signal producer for continuously reading a result from the Realm database.

     - parameter makeResults: A function to create a `Results` value, given a Realm database.
     */
    
    public func realmResultsProducer<Value>(makeResults: @escaping (Realm) -> Results<Value>)
        -> SignalProducer<Results<Value>, NSError>
    {
        return realmUpdatesProducer(makeResults: makeResults).attemptMap({ change in
            switch change
            {
            case let .initial(values):
                return .success(values)
            case let .update(values, _, _, _):
                return .success(values)
            case let .error(error):
                return .failure(error as NSError)
            }
        })
    }
}
