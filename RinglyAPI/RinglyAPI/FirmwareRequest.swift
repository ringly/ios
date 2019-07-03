import Foundation

// MARK: - Requests
public enum FirmwareRequest
{
    // MARK: - Cases

    /// Requests all firmware versions for an hardware version.
    case all(hardware: String)

    /// Requests the latest firmware versions, if any, given a set of current firmware versions.
    case versions(hardware: String, application: String?, bootloader: String?, softdevice: String?, forceResults: Bool)
}

extension FirmwareRequest: RequestProviding, ResponseProcessing
{
    // MARK: - Request
    public func request(for baseURL: URL) -> URLRequest?
    {
        return URLRequest(method: .get, baseURL: baseURL, relativeURLString: "firmware", queryItems: queryItems)
    }

    /// The URL parameters that will be used to request the endpoint.
    private var parameters: [(String, String)]
    {
        switch self
        {
        case .all(let hardware):
            return [("hardware", hardware), ("all", "true")]

        case .versions(let hardware, let application, let bootloader, let softdevice, let forceResults):
            let iOS = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

            let optionals = [
                ("hardware", hardware),
                ("application", application?.components(separatedBy: "+").first),
                ("bootloader", bootloader),
                ("softdevice", softdevice),
                ("ios_application", iOS),
                ("force", forceResults ? "true" : "false")
            ]

            return optionals.flatMap({ key, value in value.map({ (key, $0) }) })
        }
    }

    private var queryItems: [URLQueryItem]
    {
        return parameters.map(URLQueryItem.init)
    }

    public typealias Output = FirmwareResult
}
