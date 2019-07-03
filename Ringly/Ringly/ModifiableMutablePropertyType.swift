import ReactiveSwift

/// A protocol encoding the `pureModify` member of `MutableProperty`.
protocol ModifiableMutablePropertyType: MutablePropertyProtocol
{
    /// A pure-function version of `modify` (or: `modify` from ReactiveCocoa 4).
    ///
    /// - Parameter function: A transformation function from an old value to a new value.
    /// - Returns: The old value.
    @discardableResult
    func pureModify(_ function: (Value) -> Value) -> Value
}

extension MutableProperty: ModifiableMutablePropertyType
{
    /// A pure-function version of `modify` (or: `modify` from ReactiveCocoa 4).
    ///
    /// - Parameter function: A transformation function from an old value to a new value.
    /// - Returns: The old value.
    @discardableResult
    func pureModify(_ function: (Value) -> Value) -> Value
    {
        return modify { mutable in
            let old = mutable
            mutable = function(old)
            return old
        }
    }
}
