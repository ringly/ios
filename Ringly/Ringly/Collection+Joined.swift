extension BidirectionalCollection where Iterator.Element == String, SubSequence.Iterator.Element == String, Index == Int
{
    /// Uses the behavior of `joined(singleSeparator:initialSeparators:lastSeparator:)` with localized separators.
    func joinedWithLocalizedSeparators() -> String?
    {
        return joined(
            singleSeparator: tr(.wordSeparatorSingle),
            initialSeparators: tr(.wordSeparatorMultipleInitial),
            lastSeparator: tr(.wordSeparatorMultipleLast)
        )
    }

    /// Joins the collection's elements with different separators depending on element count and index. If the
    /// collection is empty, returns `nil`. If the collection contains one item, returns that item.
    ///
    /// - Parameters:
    ///   - singleSeparator: A separator to be used between the elements of a collection of two items.
    ///   - initialSeparators: A separator to be used between the first `N - 1` items of a collection of `N` items,
    ///                        where `N > 2`.
    ///   - lastSeparator: A separator to be used between the last two items of a collection of `N` items,
    ///                    where `N > 2`.
    /// - Returns: A joined string, or `nil` for a collection of 0 items.
    func joined(singleSeparator: String, initialSeparators: String, lastSeparator: String) -> String?
    {
        switch count
        {
        case 0:
            return nil
        case 1:
            return self[0]
        case 2:
            return joined(separator: singleSeparator)
        default:
            return [dropLast().joined(separator: initialSeparators), last!].joined(separator: lastSeparator)
        }
    }
}
