import Foundation
import ReactiveSwift
import enum Result.NoError

/// A protocol for types that can write `SourcedUpdate` values to a store.
public protocol SourcedUpdatesSink
{
    /**
     A producer that starts the passed-in producer of `SourcedUpdate` values and writes values yielded to the store.

     - parameter updatesProducer: a producer of `SourcedUpdate` values.
     */
    
    func writeSourcedUpdatesProducer(_ updatesProducer: SignalProducer<SourcedUpdate, NoError>)
        -> SignalProducer<(), NoError>
}
