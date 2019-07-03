import Foundation
import ReactiveSwift
import RinglyExtensions

/// The result of parsing a `com.ringly.ringly` URL or a universal link.
indirect enum URLAction: Equatable
{
    // MARK: - Actions

    /// A firmware version should be installed on the peripheral.
    case dfu(hardware: [String], application: String)

    /// A multi-URL endpoint.
    case multi([URLAction])

    /// Prompts the user to reset her password, if she is not already logged in.
    case resetPassword(token: String)

    /// Collects diagnostic data and sends it to Ringly support via email.
    case collectDiagnosticData(queryItems:[URLQueryItem]?)

    /// Enables or disables developer mode.
    case developerMode(enable: Bool)

    /// Enables the review prompt immediately.
    case review
    
    /// Open specific tab
    case openTab(tabItem: TabBarViewControllerItem)
    
    /// Push Mindfulness
    case mindfulness
    
    case universal(url: URL?)
}

extension URLAction
{
    // MARK: - Parsing Initializers

    /// Parses a `com.ringly.ringly` URL.
    init?(url: URL)
    {
        // make sure we have the correct URL scheme
        guard url.scheme?.lowercased().hasPrefix("com.ringly.ringly") ?? false else { return nil }
        
        // convert to URL components, extract required data
        guard
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let host = urlComponents.host,
            let endpoint = URLActionEndpoint(rawValue: host.lowercased())
        else {
            return nil
        }

        let pathComponents = urlComponents.path.components(separatedBy: "/")

        switch endpoint
        {
        case .dfu:
            // a query string is required for this URL.
            guard let components = urlComponents.queryItems else { return nil }

            // extract hardware versions
            let hardware = components
                .filter({ item in item.name == "hardware" })
                .flatMap({ item in item.value })

            // extract application version, and make sure that we have more than one hardware version
            guard let application = components
                .first(where: { item in item.name == "application" })
                .flatMap({ item in item.value }), hardware.count > 0
            else { return nil }

            self = .dfu(hardware: hardware, application: application)

        case .multi:
            // parse the URLs to an array
            guard let URLs = urlComponents.queryItems?.flatMap({ item in
                item.value.flatMap(Foundation.URL.init)
            }) else {
                return nil
            }
            
            self = .multi(URLs.flatMap({ URL in URLAction(url: URL) }))

        case .resetPassword:
            guard let token = pathComponents.last, token.characters.count > 0 else {
                return nil
            }

            self = .resetPassword(token: token)

        case .collectDiagnosticData:
            self = URLAction(collectDiagnosticDataQueryItems: urlComponents.queryItems)

        case .developerMode:
            guard let endpoint = pathComponents.last.flatMap(EnableDisableEndpoint.init) else {
                return nil
            }

            self = .developerMode(enable: endpoint == .enable)

        case .review:
            self = .review
        case .universal:
            if let urlQueryItem = urlComponents.queryItems?.filter({ $0.name == "url" }).first {
                let url = URL.init(string: urlQueryItem.value!)
                self = .universal(url: url)
            } else {
                self = .universal(url: nil)
            }
        }
    }

    /// Parses a universal link URL.
    init?(universalLinkURL: URL)
    {
        let components = universalLinkURL.pathComponents
        let isAppNav = components.count >= 3 && components[1].lowercased() == "app" && components[2].characters.count > 0
        let isMindfulness = isAppNav && components[2] == "mindfulness"
        
        if components.count == 4
           && components[1].lowercased() == "users"
           && components[2].lowercased() == "reset-password"
           && components[3].characters.count > 0
        {
            self = .resetPassword(token: components[3])
        }
        else if components.count == 2 && components[1].lowercased() == "diagnostic"
        {
            self = URLAction(collectDiagnosticDataQueryItems: URLComponents(
                url: universalLinkURL,
                resolvingAgainstBaseURL: false
            )?.queryItems)
        }
        else if isMindfulness {
            self = .multi([.openTab(tabItem: .activity), .mindfulness])
        }
        else if isAppNav {
            if let tabItem = TabBarViewControllerItem(rawValue: components[2]) {
                self = .openTab(tabItem: tabItem)
            } else {
                return nil
            }
        }
        else
        {
            return nil
        }
    }

    /// Retrieves the `reference` value from the URL, if any, then returns `collectDiagnosticData` URL action.
    private init(collectDiagnosticDataQueryItems: [URLQueryItem]?)
    {
        self = .collectDiagnosticData(queryItems: collectDiagnosticDataQueryItems)
    }
}

func ==(lhs: URLAction, rhs: URLAction) -> Bool
{
    switch (lhs, rhs)
    {
    case (.dfu(let lhsHardware, let lhsApplication), .dfu(let rhsHardware, let rhsApplication)):
        return lhsHardware == rhsHardware && lhsApplication == rhsApplication

    case (.multi(let lhsResults), .multi(let rhsResults)):
        return lhsResults == rhsResults

    case (.resetPassword(let lhsToken), .resetPassword(let rhsToken)):
        return lhsToken == rhsToken

    case (.collectDiagnosticData, .collectDiagnosticData):
        return true

    case let (.developerMode(leftEnable), .developerMode(rightEnable)):
        return leftEnable == rightEnable

    case (.review, .review):
        return true

    default:
        return false
    }
}

private enum URLActionEndpoint: String
{
    case dfu = "dfu"
    case multi = "multi"
    case resetPassword = "reset-password"
    case collectDiagnosticData = "collect-diagnostic-data"
    case developerMode = "developer-mode"
    case review = "review"
    case universal = "universal"
}

private enum EnableDisableEndpoint: String
{
    case enable = "enable"
    case disable = "disable"
}
