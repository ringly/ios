/// The reason for indeterminate DFU activity.
public enum ActivityReason
{
    /// The package is downloading.
    case downloading

    /// Waiting for a package component write to start.
    case waitingForWriteStart

    /// A package component has finished writing.
    case writeCompleted

    /// A device is being forgotten.
    case forgettingDevice

    /// We are waiting for a peripheral to pair again.
    case waitingForRequiredPair
}
