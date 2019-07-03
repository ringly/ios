import ReactiveSwift
import Result
import UIKit

extension Reactive where Base: UIControl
{
    /// A signal producer for the control's `highlighted` state.
    public var highlighted: SignalProducer<Bool, NoError>
    {
        return producerFor(keyPath: "highlighted")
    }
}
