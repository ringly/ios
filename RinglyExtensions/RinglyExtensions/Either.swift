import ReactiveSwift

/// A standard-issue left/right generic either type.
///
/// If considering expanding this type in the future, it's probably better to just add this framework instead:
/// https://github.com/robrix/Either
public enum Either<L, R>
{
    // MARK: - Cases

    /// The left case, of type `L`.
    case left(L)

    /// The right case, of type `R`.
    case right(R)
}

extension Either
{
    // MARK: - Values

    /// The left value, if applicable, or `nil`.
    public var leftValue: L?
    {
        switch self
        {
        case .left(let left):
            return left
        default:
            return nil
        }
    }

    /// The right value, if applicable, or `nil`.
    public var rightValue: R?
    {
        switch self
        {
        case .right(let right):
            return right
        default:
            return nil
        }
    }

    /**
     Applies functions of the same return type to each `Either` case.

     - parameter left:  A function to apply to `.left` eithers.
     - parameter right: A function to apply to `.right` eithers.
     */
    public func analysis<T>(left: (L) -> T, right: (R) -> T) -> T
    {
        switch self
        {
        case let .left(leftValue):
            return left(leftValue)
        case let .right(rightValue):
            return right(rightValue)
        }
    }
}

public func ==<L: Equatable, R: Equatable>(lhs: Either<L, R>, rhs: Either<L, R>) -> Bool
{
    switch (lhs, rhs)
    {
    case let (.left(lhsValue), .left(rhsValue)):
        return lhsValue == rhsValue
    case let (.right(lhsValue), .right(rhsValue)):
        return lhsValue == rhsValue
    default:
        return false
    }
}

public func ==<O: OptionalProtocol, L: Equatable, R: Equatable>(lhs: O, rhs: O) -> Bool where O.Wrapped == Either<L, R>
{
    switch (lhs.optional, rhs.optional)
    {
    case let (.some(lhsEither), .some(rhsEither)):
        return lhsEither == rhsEither
    case (.none, .none):
        return true
    default:
        return false
    }
}
