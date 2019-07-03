import RinglyAPI

/// Represents information saved about a peripheral, so that the same peripheral can be retrieved the next time that the
/// app runs.
struct SavedPeripheral
{
    // MARK: - Properties

    /// The peripheral's identifier.
    let identifier: UUID

    /// The peripheral's name.
    let name: String?

    /// The peripheral's application version.
    let applicationVersion: String?
    
    /// Activity Tracking Support
    let activityTrackingSupport: RLYPeripheralFeatureSupport?
}

extension SavedPeripheral
{
    // MARK: - Derived Properties

    /// The saved peripheral's short name, if any.
    var shortName: String?
    {
        return RLYPeripheralShortNameFromName(name)
    }
}

extension SavedPeripheral: Coding
{
    // MARK: - Codable
    typealias Encoded = [String:Any]

    static func decode(_ encoded: Encoded) throws -> SavedPeripheral
    {
        guard let identifier = UUID(uuidString: try encoded.decode("UUID")) else {
            throw DecodeError.key("UUID", from: encoded)
        }
        
        let activityTrackingSupport = encoded["activityTrackingSupport"] as? Int

        return SavedPeripheral(
            identifier: identifier,
            name: encoded["name"] as? String,
            applicationVersion: encoded["applicationVersion"] as? String,
            activityTrackingSupport: RLYPeripheralFeatureSupport.init(rawValue: activityTrackingSupport ?? 0)
        )
    }

    var encoded: Encoded
    {
        var encoded: Encoded = ["UUID": identifier.uuidString as AnyObject]

        if let applicationVersion = self.applicationVersion
        {
            encoded["applicationVersion"] = applicationVersion as AnyObject?
        }

        if let name = self.name
        {
            encoded["name"] = name as AnyObject?
        }
        
        if let activityTrackingSupport = self.activityTrackingSupport
        {
            encoded["activityTrackingSupport"] = activityTrackingSupport.rawValue
        }

        return encoded
    }
}

extension SavedPeripheral: Equatable {}
func ==(lhs: SavedPeripheral, rhs: SavedPeripheral) -> Bool
{
    return lhs.identifier == rhs.identifier
        && lhs.name == rhs.name
        && lhs.applicationVersion == rhs.applicationVersion
}
