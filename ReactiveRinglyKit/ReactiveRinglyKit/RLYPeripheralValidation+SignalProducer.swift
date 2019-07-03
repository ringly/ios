import RinglyKit
import ReactiveSwift
import Result

extension Reactive where Base: RLYPeripheralValidation, Base: NSObject
{
    // MARK: - Validation
    public var validated: SignalProducer<Bool, NoError>
    {
        return producerFor(keyPath: "validated")
    }

    public var validationState: SignalProducer<RLYPeripheralValidationState, NoError>
    {
        return producerFor(keyPath: "validationState", defaultValue: RLYPeripheralValidationState.missingServices.rawValue)
            .map({ value in RLYPeripheralValidationState(rawValue: value)! })
    }
    
    public var waitingForCharacteristics: SignalProducer<Bool, NoError>
    {
        return producerFor(keyPath: "waitingForCharacteristics")
    }
}
