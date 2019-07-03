import Foundation

public struct WriteProgress
{
    /// The current progress.
    public let progress: Int

    /// The index of this write.
    public let index: Int

    /// The total number of writes.
    public let count: Int
}

extension WriteProgress: Equatable {}
public func ==(lhs: WriteProgress, rhs: WriteProgress) -> Bool
{
    return lhs.progress == rhs.progress && lhs.index == rhs.index && lhs.count == rhs.count
}
