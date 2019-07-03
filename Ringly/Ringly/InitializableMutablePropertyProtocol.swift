import ReactiveSwift

/// An expansion of `MutablePropertyProtocol`, requiring initialization capabilities.
protocol InitializableMutablePropertyProtocol: MutablePropertyProtocol
{
    init(_ value: Value)
}

extension MutableProperty: InitializableMutablePropertyProtocol {}
