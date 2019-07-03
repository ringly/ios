extension Collection
{
    /**
     Performs a safe indexing operation into the collection, returning `nil` if `index` is out-of-bounds.

     - parameter index: The index.
     */
    public subscript(safe index: Index) -> Iterator.Element?
    {
        return index >= startIndex && index < endIndex ? self[index] : nil
    }
}

extension Collection where Index == Int, IndexDistance == Int
{
    /// Returns a shuffled version of the collection.
    
    public func shuffled() -> [Iterator.Element]
    {
        var array = Array(self)

        if count > 1
        {
            (startIndex..<endIndex - 1).forEach({ index in
                let other = Int(arc4random_uniform(UInt32(count - index))) + index

                if other != index
                {
                    swap(&array[other], &array[index])
                }
            })
        }

        return array
    }
}
