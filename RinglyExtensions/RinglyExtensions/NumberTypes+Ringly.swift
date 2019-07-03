extension Int
{
    /**
     Returns a random integer between `minimum` and `maximum`.

     - parameter minimum: The minimum possible value.
     - parameter maximum: The maximum possible value.
     */
    public static func random(minimum: Int, maximum: Int) -> Int
    {
        precondition(maximum > minimum)
        return minimum + Int(arc4random_uniform(UInt32(maximum - minimum + 1)))
    }
}

extension Double
{
    /**
     Returns a random double between `minimum` and `maximum`.
     
     - parameter minimum: The minimum possible value.
     - parameter maximum: The maximum possible value.
     */
    public static func random(minimum: Double = 0, maximum: Double) -> Double
    {
        return minimum + Double(arc4random() % 100000) / 100000 * (maximum - minimum)
    }
}

extension CGFloat
{
    /**
     Returns a random `CGFloat` between `minimum` and `maximum`.
     
     - parameter minimum: The minimum possible value.
     - parameter maximum: The maximum possible value.
     */
    public static func random(minimum: CGFloat = 0, maximum: CGFloat) -> CGFloat
    {
        return minimum + CGFloat(arc4random() % 100000) / 100000 * (maximum - minimum)
    }
}
