import ReactiveSwift
import Result
import RinglyKit

extension Reactive where Base: RLYPeripheralBatteryInformation, Base: NSObject
{
    // MARK: - Charge
    
    /// Returns a signal produer for the peripheral's battery charge.
    ///
    /// This is a combination of the `batteryCharge` and `batteryChargeDetermined` properties. If the battery charge
    /// has not been determined, this producer will send `nil`.
    public var batteryCharge: SignalProducer<Int?, NoError>
    {
        let determined = producerFor(keyPath: "batteryChargeDetermined", defaultValue: false)
        let charge = producerFor(keyPath: "batteryCharge", defaultValue: 0)
        
        return SignalProducer.combineLatest(determined, charge).map({ determined, charge in
            return determined ? .some(charge) : .none
        })
    }

    // MARK: - State
    
    /// Returns a signal produer for the peripheral's battery state.
    ///
    /// This is a combination of the `batteryState` and `batteryStateDetermined` properties. If the battery state
    /// has not been determined, this producer will send `nil`.
    public var batteryState: SignalProducer<RLYPeripheralBatteryState?, NoError>
    {
        let determined = producerFor(keyPath: "batteryStateDetermined", defaultValue: false)
        let state = producerFor(keyPath: "batteryState", defaultValue: RLYPeripheralBatteryState.notCharging.rawValue)
            .map({ value in RLYPeripheralBatteryState(rawValue: value)! })
        
        return SignalProducer.combineLatest(determined, state).map({ determined, state in
            return determined ? .some(state) : .none
        })
    }
    
    /// Returns a signal producer of booleans, which represent whether or not the peripheral is charging.
    public var charging: SignalProducer<Bool, NoError>
    {
        return batteryState.map({ state in state == .some(.charging) })
    }
    
    /// Returns a signal producer of booleans, which represent whether or not the peripheral is charging or charged.
    public var chargingOrCharged: SignalProducer<Bool, NoError>
    {
        return batteryState.map({ state in
            state == .some(.charging) || state == .some(.charged)
        })
    }
}
