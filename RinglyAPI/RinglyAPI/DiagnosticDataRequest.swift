import Foundation

/// A request type for uploading users' diagnostic data to the API.
public struct DiagnosticDataRequest
{
    // MARK: - Initialization

    /// Initializes a diagnostic data request.
    ///
    /// - Parameters:
    ///   - reference: The reference value for the diagnostic data upload (typically a Zendesk thread, but transparent
    ///                to the iOS app).
    ///   - files: The files attached to the endpoint.
    public init(queryItems: [URLQueryItem]?, files: [MultipartFile])
    {
        self.queryItems = queryItems
        self.files = files
    }

    // MARK: - Information

    /// The reference value for the diagnostic data upload (typically a Zendesk thread, but transparent to the iOS app).
    public let queryItems: [URLQueryItem]?

    // MARK: - Files

    /// The files attached to the endpoint.
    public let files: [MultipartFile]

    // MARK: - Boundary

    /// The boundary value to use for `multipart/form-data`.
    fileprivate let boundary: String = "boundary-\(UUID().uuidString)"
}

extension DiagnosticDataRequest: RequestProviding
{
    public func request(for baseURL: URL) -> URLRequest?
    {
        let validQueryItems = queryItems?.filter({ $0.value != nil }) ?? []
        
        let body = Data(
            multipartFields: validQueryItems.map({ MultipartField(name: $0.name, value: $0.value!) }),
            multipartFiles: files,
            boundary: boundary
        )

        return URLRequest(
            method: .post,
            baseURL: baseURL,
            relativeURLString: "users/collect-diagnostics",
            body: body,
            headerFields: ["Content-Type": "multipart/form-data; boundary=\(boundary)"]
        )
    }
}
