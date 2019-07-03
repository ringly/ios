import Foundation
import RinglyAPI

/// An application supported by the Ringly app.
struct SupportedApplication
{
    /// An array of applications supported by the Ringly app.
    static let all: [SupportedApplication] = {
        if let file = Bundle.main.path(forResource: "Apps", ofType: "plist"),
           let array = NSArray(contentsOfFile: file) as? [[String:AnyObject]]
        {
            return array.flatMap({ dictionary in
                if let app = try? SupportedApplication.decode(dictionary)
                {
                    return app
                }
                else
                {
                    SLogNotifications("Couldn't parse app \(dictionary)")
                    return nil
                }
            })
        }
        else
        {
            SLogNotifications("Error loading app file!")
            return []
        }
    }()
    
    /**
     Returns `true` if the application with the specified URL scheme is installed.
     
     This function uses `-[UIApplication canOpenURL:]`, so the requested scheme must be added to the
     `LSApplicationQueriesSchemes` array in `Info.plist`.
     
     There are six built-in schemes, which represent apps provided by iOS, for which this function will always return
     `true`. They are `phone`, `textmessage`, `email`, `calendar`, `reminders`, and `com.ringly.ringly`. Passing one of these schemes will
     not result in a call to `-[UIApplication canOpenURL:]`.
     
     - parameter scheme: The URL scheme.
     */
    static func withSchemeIsInstalled(_ scheme: String) -> Bool
    {
        #if arch(i386) || arch(x86_64)
            return true
        #else
            if scheme == "phone" ||
               scheme == "textmessage" ||
               scheme == "email" ||
               scheme == "calendar" ||
               scheme == "reminders" ||
               scheme == "com.ringly.ringly"
            {
                return true
            }
            else if let url = URL(string: "\(scheme)://")
            {
                return UIApplication.shared.canOpenURL(url)
            }
            else
            {
                return false
            }
        #endif
    }
    
    /// The name of the app.
    let name: String
    
    /// The app's URL scheme.
    let scheme: String
    
    /// The app's bundle identifiers.
    let identifiers: [String]
    
    /// The name to use for the app in analytics events.
    let analyticsName: String
}

extension SupportedApplication: Equatable {}
func ==(a: SupportedApplication, b: SupportedApplication) -> Bool
{
    return a.scheme == b.scheme
}

extension SupportedApplication: Hashable
{
    var hashValue: Int
    {
        return scheme.hashValue
    }
}

extension SupportedApplication: Decoding
{
    typealias Encoded = [String:Any]

    static func decode(_ encoded: Encoded) throws -> SupportedApplication
    {
        let identifiers: String = try encoded.decode("Identifiers")

        return try SupportedApplication(
            name: encoded.decode("Name"),
            scheme: encoded.decode("Scheme"),
            identifiers: identifiers.components(separatedBy: ","),
            analyticsName: encoded.decode("Analytics")
        )
    }
}
