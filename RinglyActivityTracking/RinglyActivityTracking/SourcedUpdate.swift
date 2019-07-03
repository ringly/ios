import RinglyKit

/// An update, associated with a source value.
public struct SourcedUpdate
{
    // MARK: - Initialization

    /**
     Initializes a `SourcedUpdate`.

     - parameter macAddress: The MAC address of the source of the update.
     - parameter update: The update.
     */
    public init(macAddress: Int64, update: RLYActivityTrackingUpdate)
    {
        self.macAddress = macAddress
        self.update = update
    }

    // MARK: - Properties

    /// The MAC address of the source of the update.
    public let macAddress: Int64

    /// The update.
    public let update: RLYActivityTrackingUpdate
}

extension SourcedUpdate: Hashable
{
    public var hashValue: Int
    {
        return macAddress.hashValue ^ update.hashValue
    }
}

public func ==(lhs: SourcedUpdate, rhs: SourcedUpdate) -> Bool
{
    return lhs.macAddress == rhs.macAddress && lhs.update == rhs.update
}
