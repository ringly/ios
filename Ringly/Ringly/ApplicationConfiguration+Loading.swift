import Foundation
import UIKit

/// The default apps listed at the top of alerts tab: phone, messages, calendar, and ringly
private let numberDefaultApps = 4

extension ApplicationConfiguration
{
    /// The result of loading application configurations.
    struct LoadResult: Equatable
    {
        /// The configurations that were loaded or newly-created.
        let configurations: [ApplicationConfiguration]

        /// The new applications that were added.
        let newApplications: [SupportedApplication]
    }

    /// Loads application configurations from saved encoded dictionary values.
    ///
    /// - Parameters:
    ///   - encodedConfigurations: The saved encoded application configurations.
    ///   - supportedApplications: The array of applications to support.
    ///   - makeNewConfiguration: Creates a new configuration, if one is not present in `encodedConfigurations`.
    /// - Returns: A value containing the application configuration and the newly-added applications. If
    ///            `savedDictionaries` is `nil`, no applications are considered newly-added.
    static func loaded(from encodedConfigurations: [[String:Any]]?,
                       supportedApplications: [SupportedApplication],
                       makeNewConfiguration: (SupportedApplication, Int) -> ApplicationConfiguration)
        -> LoadResult
    {
        let encodedDictionary = encodedConfigurations?.mapDictionaryKeys({ dictionary in
            (dictionary[ApplicationConfiguration.applicationNameKey] as? String)
                ?? "" // app not found, will be ignored in final set
        })

        // sort the applications alphabetically, but leave the primary (phone, message, calendar, reminders) at the top
        let sortedApplications = supportedApplications.prefix(numberDefaultApps) + supportedApplications.dropFirst(numberDefaultApps).sorted(by: {
            $0.name.uppercased() < $1.name.uppercased()
        })

        typealias Pair = (configuration: ApplicationConfiguration, new: SupportedApplication?)

        let pairs = sortedApplications.enumerated().map({ index, application -> Pair in
            // find a saved dictionary if we have one
            if let dictionary = encodedDictionary?[application.scheme]
            {
                return (
                    configuration: ApplicationConfiguration(application: application, encoded: dictionary),
                    new: nil
                )
            }
            else
            {
                return (
                    configuration: makeNewConfiguration(application, index),
                    new: encodedDictionary != nil ? application : nil
                )
            }
        })

        return LoadResult(
            configurations: pairs.map({ $0.configuration }),
            newApplications: pairs.flatMap({ $0.new })
        )
    }

    /// Loads application configurations from a property list file.
    ///
    /// - Parameters:
    ///   - filePath: The path to the property list file.
    ///   - supportedApplications: The array of applications to support.
    ///   - makeNewConfiguration: Creates a new configuration, if one is not present in `encodedConfigurations`.
    /// - Returns: A value containing the application configuration and the newly-added applications. If there are no
    ///            saved configurations at `filePath`, no applications are considered newly-added.
    static func loaded(from filePath: String,
                       supportedApplications: [SupportedApplication],
                       makeNewConfiguration: (SupportedApplication, Int) -> ApplicationConfiguration)
        -> LoadResult
    {
        return loaded(
            // read the application configurations from the file, and map to a dictionary by app name
            from: (NSArray(contentsOfFile: filePath) as? [[String:Any]]),
            supportedApplications: supportedApplications,
            makeNewConfiguration: makeNewConfiguration
        )
    }

    /// A default implementation for the `makeNewConfiguration` parameter of the `loaded` functions.
    ///
    /// - Parameters:
    ///   - application: The application that has been added.
    ///   - index: The index of the application in the support list.
    static func defaultMakeNewConfiguration(application: SupportedApplication, index: Int) -> ApplicationConfiguration
    {
        let defaultColors: [DefaultColor] = [.blue, .green, .purple, .red]

        let isBuiltIn = index < numberDefaultApps
        let color = index < defaultColors.count ? defaultColors[index] : .none
        let vibration = RLYVibrationFromCount(UInt8(max(4 - index, 1)))

        return ApplicationConfiguration(
            application: application,
            color: color,
            vibration: vibration,
            activated: isBuiltIn
        )
    }
}

func ==(lhs: ApplicationConfiguration.LoadResult, rhs: ApplicationConfiguration.LoadResult) -> Bool
{
    return lhs.configurations == rhs.configurations && lhs.newApplications == rhs.newApplications
}

extension ApplicationConfiguration.LoadResult
{
    /// If the load result contains any new applications, creates a local notification announcing their support.
    ///
    /// - Parameter fireDate: The fire date for the notification.
    /// - Returns: A local notification, or `nil`.
    func localNotificationForNewApplicationsOnDevice(fireDate: Date?) -> UILocalNotification?
    {
        let installed = newApplications.filter({ SupportedApplication.withSchemeIsInstalled($0.scheme) })

        return installed.map({ $0.name }).joinedWithLocalizedSeparators().map({ description in
            let notification = UILocalNotification()
            notification.soundName = UILocalNotificationDefaultSoundName
            notification.alertTitle = tr(.applicationsNewSupportAlertTitle)
            notification.alertBody = tr(.applicationsNewSupportAlertBody(description))
            notification.fireDate = fireDate
            notification.userInfo = UILocalNotification.userInfo(forNewApplications: installed)
            return notification
        })
    }
}

extension LocalNotification
{
    /// A key for determining the behavior of `isForNewApplications`.
    private static var forNewApplicationsKey: String { return "forNewApplications" }

    /// A key containing the application identifiers of newly-added applications.
    static var newApplicationIdentifiersKey: String { return "newApplicationIdentifiers" }

    /// Creates a user-info dictionary for a new application support notification.
    ///
    /// - Parameter newApplications: The new applications to include in the notification.
    fileprivate static func userInfo(forNewApplications newApplications: [SupportedApplication]) -> [String:Any]
    {
        return [
            forNewApplicationsKey: true,
            newApplicationIdentifiersKey: newApplications.map({ $0.identifiers })
        ]
    }

    /// `true` if the notification was created by
    /// `ApplicationConfiguration.LoadResult.localNotificationForNewApplicationsOnDevice`. Otherwise `false`.
    var isForNewApplications: Bool
    {
        return userInfo?[Self.forNewApplicationsKey] as? Bool ?? false
    }
}
