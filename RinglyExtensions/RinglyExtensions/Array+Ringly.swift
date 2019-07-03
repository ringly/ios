extension Array
{
    // MARK: - Shifting
    
    /**
     Rotates the array by the specified offset, wrapping elements that fall off the end around to the start..

     - parameter offset: The offset to use.
     */
    public func shift(by offset: Int) -> [Iterator.Element]
    {
        if offset > 0
        {
            return Array(suffix(offset)) + Array(dropLast(offset))
        }
        else if offset < 0
        {
            return Array(dropFirst(-offset)) + Array(prefix(-offset))
        }
        else
        {
            return Array(self)
        }
    }
}
