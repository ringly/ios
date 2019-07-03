import Foundation
import ReactiveSwift
import RinglyExtensions
import enum Result.NoError

extension Reactive where Base: UIDevice
{
    /// A signal producer for the device's current battery level and state.
    var battery: SignalProducer<(level: Float, state: UIDeviceBatteryState), NoError>
    {
        return SignalProducer.`defer` {
            // producers that yield the changed value when a value changes
            let state = NotificationCenter.default.reactive
                .notifications(forName: NSNotification.Name.UIDeviceBatteryStateDidChange, object: self.base)
                .map({ _ in self.base.batteryState })

            let level = NotificationCenter.default.reactive
                .notifications(forName: NSNotification.Name.UIDeviceBatteryLevelDidChange, object: self.base)
                .map({ _ in self.base.batteryLevel })

            // concat future values with the current values to yield an initial `next` and to seed `combineLatest`
            return SignalProducer.combineLatest(
                SignalProducer.concat([SignalProducer(value: self.base.batteryLevel), SignalProducer(level)]),
                SignalProducer.concat([SignalProducer(value: self.base.batteryState), SignalProducer(state)])
            ).map({ (level: $0.0, state: $0.1) })
        }
    }
}
