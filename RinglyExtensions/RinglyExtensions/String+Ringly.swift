extension String
{
    /**
     Crops the receiver to `min(characters.count, length)`.

     - parameter length: The length to trim to.
     */
    public func trimmedTo(length: Int) -> String
    {
        return characters.count > length ? substring(to: characters.index(startIndex, offsetBy: length)) : self
    }
}

public extension String
{
    /// Roughly validates the string as an email address.
    public var isValidEmailAddress: Bool
    {
        return characters.index(of: "@").map({ index in
            index != startIndex && index != endIndex && index != characters.index(before: endIndex)
        }) ?? false
    }
}

