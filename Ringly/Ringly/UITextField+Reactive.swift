import ReactiveCocoa
import ReactiveSwift
import RinglyExtensions
import UIKit
import enum Result.NoError

extension Reactive where Base: UITextField
{
    /// Yields the current text value when started, then all following text values. (`continuousTextValues` is a
    /// `Signal`, so it does not yield the current value).
    var allTextValues: SignalProducer<String?, NoError>
    {
        let base = self.base

        return SignalProducer.deferValue({ [weak base] in base?.text })
            .concat(SignalProducer(continuousTextValues))
    }
}
