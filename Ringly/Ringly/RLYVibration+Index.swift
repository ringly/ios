import RinglyKit

extension RLYVibration
{
    // MARK: - Indexes

    /**
     Initializes a vibration with an index.

     - parameter index: The index.
     */
    init(index: Int)
    {
        if let vibration = RLYVibration(rawValue: index + 1), index < 4
        {
            self = vibration
        }
        else
        {
            self = .none
        }
    }

    /// The index of the vibration.
    var index: Int
    {
        return self == .none ? 4 : rawValue - 1;
    }
}
