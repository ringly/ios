import Foundation

// MARK: - Authentication Completed
struct AuthenticationCompletedEvent
{
    let method: AnalyticsAuthenticationMethod
}

extension AuthenticationCompletedEvent: AnalyticsEventType
{
    var name: String { return "Authentication Completed" }

    var properties: [String:AnalyticsPropertyValueType]
    {
        return ["Method": method]
    }
}

// MARK: - Authentication Failed
struct AuthenticationFailedEvent
{
    let method: AnalyticsAuthenticationMethod
    let error: NSError
}

extension AuthenticationFailedEvent: AnalyticsEventType
{
    var name: String { return "Authentication Failed" }

    var properties: [String:AnalyticsPropertyValueType]
    {
        return ["Method": method, "Domain": error.domain, "Code": error.code]
    }
}

// MARK: - Authentication Method
enum AnalyticsAuthenticationMethod: String, AnalyticsPropertyValueType
{
    case login = "Login"
    case register = "Register"
}
