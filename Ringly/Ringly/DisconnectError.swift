import Foundation

/// An error paired with a time, used to track peripheral disconnection events.
final class DisconnectError: NSObject
{
    /**
     Initializes a disconnect error.
     
     - parameter error: The disconnection error.
     - parameter time:  The disconnection time.
     */
    init(error: NSError, time: CFAbsoluteTime)
    {
        self.error = error
        self.time = time
    }
    
    /// The disconnection error.
    let error: NSError
    
    /// The disconnection time.
    let time: CFAbsoluteTime
    
    /// A string representation of the disconnection error.
    override var description: String
    {
        return "\(error) at \(time)"
    }
}
