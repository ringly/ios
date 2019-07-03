import Foundation
import Result
import ReactiveSwift
import RinglyKit

// MARK: - Notification Features

extension RLYANCSNotification
{
    // MARK: - Signatures

    /// A signature for the notification, to be used in preventing duplicates.
    var ANCSV1Signature: String
    {
        return [
            "\(category.rawValue)",
            applicationIdentifier,
            title,
            date.map({ date in "\(UInt(date.timeIntervalSince1970))" }) ?? "none"
        ].joined(separator: "~*~")
    }

    /**
     Returns `true` if the notification's signature is contained in the array of signatures.

     - parameter signatures: The notification signatures to check.
     */
    func alreadySent(_ signatures: [String]) -> Bool
    {
        return signatures.contains(ANCSV1Signature)
    }
}

extension RLYANCSNotification
{
    // MARK: - Applications

    /**
     Performs the applications test on the notification, returning the application configuration if successful.

     - parameter applicationsService: The applications service to use.
     */
    func applicationsTest(configurations: [ApplicationConfiguration])
        -> Result<ApplicationConfiguration, ANCSV1RejectionReason>
    {
        if let configuration = configurations
            .configurationMatching(applicationIdentifier: applicationIdentifier, trimLengthToMatch: true)
        {
            if configuration.activated
            {
                return .success(configuration)
            }
            else
            {
                return .failure(.applicationNotActivated)
            }
        }
        else
        {
            return .failure(.noApplicationConfiguration)
        }
    }
}

extension RLYANCSNotification
{
    // MARK: - Contacts

    /// Whether or not a notification supports Inner Ring filtering.
    fileprivate var supportsInnerRing: Bool
    {
        return applicationIdentifier.caseInsensitiveCompare("com.apple.mobilephone") == .orderedSame
            || applicationIdentifier.caseInsensitiveCompare("com.apple.facetime") == .orderedSame
            || applicationIdentifier.caseInsensitiveCompare("com.apple.MobileSMS") == .orderedSame
    }

    /**
     Returns the contact configuration associated with the notification, if any.

     - parameter contactsService: The contacts service to request contacts from.
     */
    fileprivate func contactConfigurationIn(_ configurations: [ContactConfiguration])
        -> ContactConfiguration?
    {
        if supportsInnerRing
        {
            return configurations.contactConfiguration(title, trimLengthToMatch: true)
        }
        else
        {
            return nil
        }
    }

    /**
     Performs the contacts test on the notification.

     - parameter contactsService:  The contacts configurations to search.
     - parameter innerRingEnabled: Whether or not Inner Ring is enabled.

     - returns: A result. A successful value is an optional contact configuration - if the value is `nil`, the
                notification passed the test, but does not have a contact configuration associated with it.
     */
    func contactsTest(configurations: [ContactConfiguration], innerRingEnabled: Bool)
        -> Result<ContactConfiguration?, ANCSV1RejectionReason>
    {
        if let configuration = contactConfigurationIn(configurations)
        {
            return .success(configuration)
        }
        else if !innerRingEnabled || !supportsInnerRing
        {
            return .success(nil)
        }
        else
        {
            return .failure(.contacts)
        }
    }
}

extension RLYANCSNotification
{
    // MARK: - Dates

    /**
     Performs a date test on the notification.

     - parameter currentDate:          The current date to use.
     - parameter pastCutoffInterval:   The past cutoff interval to use.
     - parameter futureCutoffInterval: The future cutoff interval to use.
     */
    
    func dateTest(currentDate: Date,
                  pastCutoffInterval: TimeInterval,
                  futureCutoffInterval: TimeInterval)
                  -> ANCSV1RejectionReason?
    {
        // if the notification is an incoming call, we should always allow it through immediately
        guard category != .incomingCall else {
            SLogANCS("Notification is incoming phone call, ignoring oldness and allowing through")
            return nil
        }

        // ensure that the notification has a date associated with it
        guard let date = self.date else {
            return .noDate
        }

        // make sure the notification was sent within the past cutoff date
        let pastCutoffDate = currentDate.addingTimeInterval(-pastCutoffInterval)
        let passesPastCutoff = pastCutoffDate.compare(date) != .orderedDescending

        // make sure the notification was sent before the future cutoff date
        let futureCutoffDate = currentDate.addingTimeInterval(futureCutoffInterval)
        let passesFutureCutoff = futureCutoffDate.compare(date) != .orderedAscending

        return (passesPastCutoff ? nil : .tooOld(notificationDate: date, cutoffDate: pastCutoffDate))
            ?? (passesFutureCutoff ? nil : .tooNew(notificationDate: date, cutoffDate: futureCutoffDate))
            ?? flagsValue?.flags.ANCSTestRejectionReason
    }
}

extension RLYANCSNotification
{
    // MARK: - ANCS v1 Test

    /**
     Performs configuration tests on the notification.

     - parameter applicationsService: The applications service to use.
     - parameter contactsService:     The contacts service to use.
     */
    fileprivate func configurationsTest(applicationConfigurations: [ApplicationConfiguration],
                                        contactConfigurations: [ContactConfiguration],
                                        innerRingEnabled: Bool)
        -> Result<ANCSV1Configurations, ANCSV1RejectionReason>
    {
        let result = applicationsTest(configurations: applicationConfigurations)
                 &&& contactsTest(configurations: contactConfigurations, innerRingEnabled: innerRingEnabled)

        return result.map(ANCSV1Configurations.init)
    }

    /**
     Performs all tests on the notification.

     - parameter sentSignatures:      The current list of already sent notification signatures.
     - parameter applicationsService: The applications service to use.
     - parameter contactsService:     The contacts service to use.

     - returns: A result. If the value is successful, the notification should be sent to the peripheral as a
                notification.
     */
    func ANCSV1TestResult(sentSignatures: [String],
                          applicationConfigurations: [ApplicationConfiguration],
                          contactConfigurations: [ContactConfiguration],
                          innerRingEnabled: Bool)
        -> ANCSV1Result
    {
        // ensure that the message is either not a phone call or has not been already sent
        guard category == .incomingCall || !alreadySent(sentSignatures) else {
            return .failure(ANCSV1Rejection(notification: self, reason: .alreadySent))
        }

        // dateTest returns an optional error code, since there is no relevant information in a successful case
        let testResult = dateTest(currentDate: Date(), pastCutoffInterval: 3600, futureCutoffInterval: 600)
            .map({ Result(error: $0) })
            ?? configurationsTest(applicationConfigurations: applicationConfigurations,
                                  contactConfigurations: contactConfigurations,
                                  innerRingEnabled: innerRingEnabled)

        return testResult.analysis(
            ifSuccess: { (configurations: ANCSV1Configurations) -> ANCSV1Result in
                .success((self, configurations))
            },
            ifFailure: { reason -> ANCSV1Result in
                .failure(ANCSV1Rejection(notification: self, reason: reason))
            }
        )
    }
}

extension RLYANCSNotificationFlags
{
    /// Performs an ANCS test for the flags.
    ///
    /// If we fail the date test, we will still allow notifications through that are not silent or pre-existing.
    /// Apple notifications from SMS and Mail can report old dates, and will fail the test. This is a workaround
    /// to prevent dropping all of those notifications.
    var ANCSTestRejectionReason: ANCSV1RejectionReason?
    {
        if contains(.silent) && contains(.preExisting)
        {
            return .flags(self)
        }
        else
        {
            return nil
        }
    }
}

/// A type-specified `Result` type for ANCS v1 tests.
typealias ANCSV1Result = Result<(RLYANCSNotification, ANCSV1Configurations), ANCSV1Rejection>

/// The user configurations for an ANCS v1 notification.
struct ANCSV1Configurations
{
    /// The application configuration.
    let application: ApplicationConfiguration

    /// The contact configuration, if any.
    let contact: ContactConfiguration?
}
