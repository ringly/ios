import ReactiveSwift
import Result

extension OptionalProtocol where Wrapped: OptionalProtocol
{
    /// Flattens an optional-optional.
    public func flatten() -> Wrapped.Wrapped?
    {
        return optional?.optional
    }
}

/// Transforms an optional of type T?? into an optional of type T?.
public func flattenOptional<T>(_ optional: T??) -> T?
{
    return optional ?? nil
}

public func ==<A: Equatable, B: Equatable>(lhs: (A?, B?), rhs: (A?, B?)) -> Bool
{
    return lhs.0 == rhs.0 && lhs.1 == rhs.1
}

public func ==<Value: Equatable, Error: Equatable>(lhs: Result<Value?, Error>, rhs: Result<Value?, Error>) -> Bool
{
    switch (lhs, rhs)
    {
    case let (.success(lhsValue), .success(rhsValue)):
        return lhsValue == rhsValue
    case let (.failure(lhsError), .failure(rhsError)):
        return lhsError == rhsError
    default:
        return false
    }
}
