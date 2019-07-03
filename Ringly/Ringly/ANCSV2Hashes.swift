// MARK: - Hashing Protocol

/// A protocol for values that can be hashed for ANCS v2 peripherals.
protocol ANCSV2Hashable
{
    /// The ANCS v2 hash value for the value.
    var ANCSV2HashValue: UInt32 { get }
}

// MARK: - Hashing Configurations
extension ApplicationConfiguration: ANCSV2Hashable
{
    var ANCSV2HashValue: UInt32
    {
        return (UInt32(color.rawValue) << 24)
             ^ (UInt32(vibration.rawValue) << 16)
             ^ application.identifiers.ANCSV2HashValue
    }
}

extension ContactConfiguration: ANCSV2Hashable
{
    var ANCSV2HashValue: UInt32
    {
        return names.ANCSV2HashValue ^ UInt32(color.rawValue << 24)
    }
}

// MARK: - Hashing Integers
extension UInt8: ANCSV2Hashable
{
    var ANCSV2HashValue: UInt32
    {
        return UInt32(self)
    }
}

// MARK: - Hashing Strings
extension String: ANCSV2Hashable
{
    /// Returns a constant hash for a string value.
    ///
    /// This hash function uses the raw UTF-8 values, so it will be constant across application runs, a guarantee that
    /// Swift's built-in hash does not provide.
    var ANCSV2HashValue: UInt32
    {
        return utf8.ANCSV2HashValue
    }
}

// MARK: - Hashing Sequences
extension Sequence where Iterator.Element: ANCSV2Hashable
{
    var ANCSV2HashValue: UInt32
    {
        return enumerated().map({ index, value in
            value.ANCSV2HashValue.rotate(UInt32(index % 4) * 8)
        }).reduce(0, ^)
    }
}

// MARK: - Packing Hashes

/// A packed hash value.
struct ANCSV2PackedHash
{
    /// The first hash.
    let first: UInt32

    /// The second hash.
    let second: UInt32
}

extension ANCSV2PackedHash
{
    // MARK: - Packing

    /**
     Initializes a packed hash from a packed value.

     - parameter packed: The packed value.
     */
    init(packed: UInt64)
    {
        self.init(
            first: UInt32(truncatingBitPattern: packed),
            second: UInt32(truncatingBitPattern: packed >> 32)
        )
    }

    /// A packed value representation of the hash.
    var packed: UInt64
    {
        return UInt64(first) | (UInt64(second) << 32)
    }
}

extension UInt32
{
    /**
     Rotates the bit pattern of the value.

     - parameter distance: The distance to rotate.
     */
    func rotate(_ distance: UInt32) -> UInt32
    {
        let mod = distance % 32
        return mod == 0 ? self : (self << mod) | (self >> (32 - mod))
    }
}

extension ANCSV2PackedHash
{
    // MARK: - Configurations

    /**
     Creates a packed hash by hashing arrays of application and contact configurations.

     - parameter applications: The application configurations to hash.
     - parameter contacts:     The contact configurations to hash.
     */
    init(applications: [ApplicationConfiguration], contacts: [ContactConfiguration])
    {
        self.init(first: applications.ANCSV2HashValue, second: contacts.ANCSV2HashValue)
    }
}

extension ANCSV2PackedHash: Equatable {}
func ==(lhs: ANCSV2PackedHash, rhs: ANCSV2PackedHash) -> Bool
{
    return lhs.first == rhs.first && lhs.second == rhs.second
}
