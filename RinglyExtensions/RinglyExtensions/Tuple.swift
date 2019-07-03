// MARK: - Appending

/// Appends an element to a tuple.
public func append<A, B, Value>(_ tuple: (A, B), _ value: Value) -> (A, B, Value)
{
    return (tuple.0, tuple.1, value)
}

/// Appends an element to a tuple.
public func append<A, B, C, Value>(_ tuple: (A, B, C), _ value: Value) -> (A, B, C, Value)
{
    return (tuple.0, tuple.1, tuple.2, value)
}

/// Appends an element to a tuple.
public func append<A, B, C, D, Value>(_ tuple: (A, B, C, D), _ value: Value) -> (A, B, C, D, Value)
{
    return (tuple.0, tuple.1, tuple.2, tuple.3, value)
}

/// Appends an element to a tuple.
public func append<A, B, C, D, E, Value>(_ tuple: (A, B, C, D, E), _ value: Value) -> (A, B, C, D, E, Value)
{
    return (tuple.0, tuple.1, tuple.2, tuple.3, tuple.4, value)
}

// MARK: - Prepending

/// Prepends an element to a tuple.
public func prepend<A, B, Value>(_ value: Value, _ tuple: (A, B)) -> (Value, A, B)
{
    return (value, tuple.0, tuple.1)
}

// MARK: - Unwrapping

/// Unwraps a tuple of optional elements to an optional tuple.
public func unwrap<A, B>(_ a: A?, _ b: B?) -> (A, B)?
{
    if let l = a, let r = b
    {
        return (l, r)
    }
    else
    {
        return nil
    }
}

/// Converts a tuple of optional elements to an optional tuple.
public func unwrap<A, B, C>(_ a: A?, _ b: B?, _ c: C?) -> (A, B, C)?
{
    return unwrap(unwrap(a, b), c).map(append)
}

/// Converts a tuple of optional elements to an optional tuple.
public func unwrap<A, B, C, D>(_ a: A?, _ b: B?, _ c: C?, _ d: D?) -> (A, B, C, D)?
{
    return unwrap(unwrap(a, b, c), d).map(append)
}

/// Converts a tuple of optional elements to an optional tuple.
public func unwrap<A, B, C, D, E>(_ a: A?, _ b: B?, _ c: C?, _ d: D?, _ e: E?) -> (A, B, C, D, E)?
{
    return unwrap(unwrap(a, b, c, d), e).map(append)
}

/// Converts a tuple of optional elements to an optional tuple.
public func unwrap<A, B, C, D, E, F>(_ a: A?, _ b: B?, _ c: C?, _ d: D?, _ e: E?, _ f: F?) -> (A, B, C, D, E, F)?
{
    return unwrap(unwrap(a, b, c, d, e), f).map(append)
}

