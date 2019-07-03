import RealmSwift
import RinglyKit

/// A Realm model for an activity tracking update.
final class UpdateModel: Object
{
    // MARK: - Identifier

    /// Creates an identifier for an update model, given a specific timestamp and source hash.
    ///
    /// This must be determined from those attributes, so that data values that are read repeatedly will just update
    /// (effectively a no-op, assuming immutability holds on the peripheral's end) rather than adding duplicate records.
    ///
    /// - Parameters:
    ///   - timestamp: The timestamp.
    ///   - sourceHash: The source hash.
    @nonobjc static func identifier(timestamp: Int32, macAddress: Int64) -> Int64
    {
        let shift32 = (Int64(MemoryLayout<Int32>.size) * 8)
        let macAddress32 = Int32(truncatingBitPattern: macAddress) ^ Int32(truncatingBitPattern: macAddress >> shift32)
        return Int64(timestamp) | (Int64(macAddress32) << shift32)
    }

    /// The identifier (and primary key) for this model. This value should only be created with
    /// `identifier(timestamp:sourceHash:)`.
    fileprivate(set) dynamic var identifier: Int64 = 0

    // MARK: - Metadata

    /// The timestamp at which this update occurred.
    fileprivate(set) dynamic var timestamp: Int32 = 0

    /// The source MAC address for this update.
    fileprivate(set) dynamic var macAddress: Int64 = 0

    // MARK: - Steps

    /// The backing store for the walking steps, exposed as `walkingSteps`.
    ///
    /// Realm does not support unsigned integers, so we store this as a signed integer and convert bit patterns.
    @objc fileprivate dynamic var walkingBacking: Int8 = 0

    /// The backing store for the running steps, exposed as `runningSteps`.
    ///
    /// Realm does not support running integers, so we store this as a signed integer and convert bit patterns.
    @objc fileprivate dynamic var runningBacking: Int8 = 0
}

extension UpdateModel
{
    // MARK: - Initialization

    /**
     Initializes an update model from a sourced update.

     - parameter sourcedUpdate: The sourced update.
     */
    convenience init(sourcedUpdate: SourcedUpdate)
    {
        self.init(
            timestamp: Int32(sourcedUpdate.update.date.minute),
            macAddress: sourcedUpdate.macAddress,
            walkingSteps: sourcedUpdate.update.walkingSteps,
            runningSteps: sourcedUpdate.update.runningSteps
        )
    }

    /// Initializes an update model. The model's `identifier` is automatically determined.
    ///
    /// - Parameters:
    ///   - timestamp: The timestamp for the update.
    ///   - sourceHash: The source hash for the update.
    ///   - walkingSteps: The number of walking steps.
    ///   - runningSteps: The number of running steps.
    convenience init(timestamp: Int32, macAddress: Int64, walkingSteps: UInt8, runningSteps: UInt8)
    {
        self.init()

        self.identifier = UpdateModel.identifier(timestamp: timestamp, macAddress: macAddress)
        self.timestamp = timestamp
        self.macAddress = macAddress
        self.runningSteps = runningSteps
        self.walkingSteps = walkingSteps
    }
}

extension UpdateModel
{
    // MARK: - Realm
    
    /// The primary key for the update is `identifier`.
    override static func primaryKey() -> String?
    {
        return "identifier"
    }
}

extension UpdateModel
{
    // MARK: - Steps

    /// The number of walking steps for the update.
    @nonobjc fileprivate(set) var walkingSteps: UInt8
    {
        get { return UInt8(bitPattern: walkingBacking) }
        set { walkingBacking = Int8(bitPattern: newValue) }
    }

    /// The number of running steps in the update.
    @nonobjc fileprivate(set) var runningSteps: UInt8
    {
        get { return UInt8(bitPattern: runningBacking) }
        set { runningBacking = Int8(bitPattern: newValue) }
    }
}

extension UpdateModel
{
    // MARK: - HealthKit Timestamp Conversion

    /// The number of update timestamps per HealthKit timestamp.
    @nonobjc static let healthKitTimestampFactor: Int32 = 10

    /// The HealthKit timestamp for this model.
    @nonobjc var healthKitTimestamp: Int32
    {
        return timestamp / UpdateModel.healthKitTimestampFactor
    }
}

extension UpdateModel: TimestampedStepsData
{
    // MARK: - Steps Data
    var walkingStepCount: Int
    {
        return Int(walkingSteps)
    }

    var runningStepCount: Int
    {
        return Int(runningSteps)
    }
}

extension Sequence where Iterator.Element == UpdateModel
{
    /// The set of HealthKit timestamps for the update models. 
    var healthKitTimestamps: Set<Int32>
    {
        return Set(lazy.map({ $0.healthKitTimestamp }))
    }
}
