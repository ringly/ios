import RinglyKit

/// A type representing the reason that an ANCS notification was rejected (a notification was not sent to the peripheral).
struct ANCSV1Rejection: Error
{
    // MARK: - Properties

    /// The notification that was rejected.
    let notification: RLYANCSNotification
    
    /// The reason that the notification was rejected.
    let reason: ANCSV1RejectionReason
}

extension ANCSV1Rejection: CustomDebugStringConvertible
{
    // MARK: - Debug Strings
    var debugDescription: String
    {
        switch reason
        {
        case .alreadySent:
            return "Notification already sent: \(notification)"
        case .applicationNotActivated:
            return "Notification application not activated: \(notification)"
        case .contacts:
            return "Notification did not pass contacts test: \(notification)"
        case .tooOld(let notificationDate, let cutoffDate):
            return "Notification is too old: \(notification), with"
                + "\n notification date:  \(notificationDate)"
                + "\n cutoff date:        \(cutoffDate)"
        case .tooNew(let notificationDate, let cutoffDate):
            return "Notification is too old: \(notification), with"
                + "\n notification date:  \(notificationDate)"
                + "\n cutoff date:        \(cutoffDate)"
        case .noDate:
            return "No date: \(notification)"
        case .flags:
            return "Flags \(notification)"
        case .noApplicationConfiguration:
            return "Notification did not have application configuration: \(notification)"
        }
    }
}

extension ANCSV1Rejection
{
    // MARK: - Analytics

    /// The notified event to send for the rejection, if any.
    var notifiedEvent: NotifiedEvent?
    {
        let identifier = notification.applicationIdentifier

        switch reason
        {
        case .applicationNotActivated:
            return NotifiedEvent(
                applicationIdentifier: identifier,
                sent: false,
                enabled: false,
                supported: true,
                version: notification.version
            )

        case .noApplicationConfiguration:
            return NotifiedEvent(
                applicationIdentifier: identifier,
                sent: false,
                enabled: false,
                supported: false,
                version: notification.version
            )

        case .contacts:
            return NotifiedEvent(
                applicationIdentifier: identifier,
                sent: false,
                enabled: true,
                supported: true,
                version: notification.version
            )

        default:
            return nil
        }
    }
}

extension ANCSV1Rejection: Equatable {}
func ==(lhs: ANCSV1Rejection, rhs: ANCSV1Rejection) -> Bool
{
    return lhs.notification == rhs.notification && lhs.reason == rhs.reason
}

/// Enumerates the reason that an ANCS notification can be rejected.
enum ANCSV1RejectionReason: Error
{
    /// The notification was already sent.
    case alreadySent
    
    /// An application configuration found, but it was not activated.
    case applicationNotActivated
    
    /// The notification was filtered by Inner Ring.
    case contacts
    
    /// The notification's date was before the past cutoff date.
    case tooOld(notificationDate: Date, cutoffDate: Date)

    /// The notification's date was after the past cutoff date.
    case tooNew(notificationDate: Date, cutoffDate: Date)
    
    /// The notification did not have a date, and was not an incoming phone call.
    case noDate
    
    /// The notification's flags caused a rejection (the notification was silent or pre-existing)
    case flags(RLYANCSNotificationFlags)
    
    /// There was no application configuration.
    case noApplicationConfiguration
}

extension ANCSV1RejectionReason: Equatable {}
func ==(lhs: ANCSV1RejectionReason, rhs: ANCSV1RejectionReason) -> Bool
{
    switch (lhs, rhs)
    {
    case (.alreadySent, .alreadySent):
        return true
    case (.applicationNotActivated, .applicationNotActivated):
        return true
    case (.contacts, .contacts):
        return true
    case (.tooOld(let l), .tooOld(let r)):
        return l.notificationDate == r.notificationDate && l.cutoffDate == r.cutoffDate
    case (.tooNew(let l), .tooNew(let r)):
        return l.notificationDate == r.notificationDate && l.cutoffDate == r.cutoffDate
    case (.noDate, .noDate):
        return true
    case (.flags(let f1), .flags(let f2)):
        return f1 == f2
    case (.noApplicationConfiguration, .noApplicationConfiguration):
        return true
    default:
        return false
    }
}
