import Foundation
import HealthKit
import ReactiveSwift
import enum Result.NoError

/// A protocol for types that can save HealthKit data.
public protocol HealthKitSaveSink
{
    // MARK: - Authorization Status

    /// A producer for the current authorization status for steps data.
    var stepsAuthorizationStatusProducer: SignalProducer<HKAuthorizationStatus, NoError> { get }

    /// A producer for the current authorization status for mindful minute data.
    var mindfulMinuteAuthorizationStatusProducer: SignalProducer<HKAuthorizationStatus, NoError> { get }

    // MARK: - Saving Objects

    /**
     A producer for saving HealthKit objects to the sink.

     - parameter objects: The objects.
     */
    func saveObjectsProducer(_ objects: [HKObject]) -> SignalProducer<(), NSError>

    /**
     A producer that deletes objects with the specified UUIDs.

     - parameter UUIDStrings: The external UUID strings to delete.
     - parameter type:        The type of the objects to delete.
     */
    func deleteObjectsProducer(UUIDStrings: [String], type: HKObjectType) -> SignalProducer<(), NSError>
}

extension HealthKitSaveSink
{
    // MARK: - Updating Objects

    /**
     Deletes any objects matching external UUIDs in `objects`, then saves `objects`.

     HealthKit records are immutable, and cannot be updated or overwritten by using the same external UUID. Therefore,
     this method is necessary to perform updates. There is no support for transactions, so this is unfortunately not
     perfectly reliable.

     - parameter objects: The objects to update.
     - parameter type:    The type of objects to update. This parameter is necessary to perform a predicate-based delete
                          operation.
     */
    func updateObjectsProducer(_ objects: [HKObject], type: HKObjectType) -> SignalProducer<(), NSError>
    {
        let UUIDStrings = objects.flatMap({ object in
            object.metadata?[HKMetadataKeyExternalUUID] as? String
        })

        return deleteObjectsProducer(UUIDStrings: UUIDStrings, type: type)
            .mapError(HealthKitExtraErrorContext.deletingObject.add)
            .then(saveObjectsProducer(objects).mapError(HealthKitExtraErrorContext.savingObject.add))
    }
}

/// Since HealthKit doesn't have transactions, adds error info so that we can tell from where an error occurred (i.e.
/// a saving error is particularly bad because deletion has already occurred).
enum HealthKitExtraErrorContext: String
{
    /// The error occurred while deleting an object.
    case deletingObject

    /// The error occurred while saving an object.
    case savingObject
}

extension HealthKitExtraErrorContext
{
    func add(to error: NSError) -> NSError
    {
        var userInfo = error.userInfo
        userInfo[NSUnderlyingErrorKey] = error
        userInfo["HealthKitExtraErrorContext"] = self.rawValue

        return NSError(domain: error.domain, code: error.code, userInfo: userInfo)
    }
}
