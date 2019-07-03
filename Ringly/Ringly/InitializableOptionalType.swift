import protocol ReactiveSwift.OptionalProtocol

/// An expansion of ReactiveCocoa's `OptionalProtocol`, which also requires that types be capable of initialization with
/// an `Optional` value.
protocol InitializableOptionalType: OptionalProtocol
{
    init(optional: Wrapped?)
}

extension Optional: InitializableOptionalType
{
    init(optional: Wrapped?)
    {
        self = optional
    }
}
