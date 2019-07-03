import Foundation

// MARK: - Adding Headers

/// Transforms an endpoint by adding HTTP headers.
internal struct AddedHTTPHeadersRequest
{
    /// The request to add HTTP headers to.
    let base: RequestProviding

    /// The additional headers.
    let headers: [String:String]
}

extension AddedHTTPHeadersRequest: RequestProviding
{
    func request(for baseURL: URL) -> URLRequest?
    {
        var request = base.request(for: baseURL)
        var fields = request?.allHTTPHeaderFields ?? [:]

        for (field, value) in headers
        {
            fields[field] = value
        }

        request?.allHTTPHeaderFields = fields

        return request
    }
}
