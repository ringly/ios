import ReactiveSwift
import RinglyKit
import enum Result.NoError

extension Reactive where Base: RLYPeripheralActivityTracking, Base: NSObject
{
    // MARK: - Activity Tracking Support

    /// A signal producer for the peripheral's `activityTrackingSupport` property.
    public var activityTrackingSupport: SignalProducer<RLYPeripheralFeatureSupport, NoError>
    {
        return producerFor(keyPath: "activityTrackingSupport").map({ RLYPeripheralFeatureSupport(rawValue: $0)! })
    }

    /// A signal producer for the peripheral's `subscribedToActivityNotifications` property.
    public var subscribedToActivityNotifications: SignalProducer<Bool, NoError>
    {
        return producerFor(keyPath: "subscribedToActivityNotifications")
    }
}
