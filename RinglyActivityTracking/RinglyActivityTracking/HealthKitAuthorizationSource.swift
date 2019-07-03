import Foundation
import HealthKit
import ReactiveSwift

/// A protocol for types that provide HealthKit authorization.
public protocol HealthKitAuthorizationSource
{
    // MARK: - Requesting Authorization

    /**
     A producer for requesting HealthKit authorization.

     - parameter shareTypes: The types to share.
     - parameter readTypes:  The types to read.
     */
    
    func requestAuthorizationProducer(shareTypes: Set<HKSampleType>, readTypes: Set<HKObjectType>)
        -> SignalProducer<(), NSError>

    // MARK: - Current Authorization Status

    /**
     Returns the current sharing authorization status for the specified type.

     - parameter type: The type.
     */
    
    func authorizationStatusForType(_ type: HKObjectType) -> HKAuthorizationStatus
}
