import Foundation

extension NSError
{
    static func userInfoForHTTPResponse(_ response: HTTPURLResponse, JSON: Any) -> [String:Any]
    {
        // parse custom failure reason text from the API
        guard let error = (JSON as? [String:AnyObject])?["error"] as? [String:Any] else {
            return [NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: response.statusCode)]
        }

        if let title = error["title"] as? String, let body = error["body"] as? String
        {
            return [NSLocalizedDescriptionKey: title, NSLocalizedFailureReasonErrorKey: body]
        }
        else if let message = error["message"] as? String
        {
            return [NSLocalizedFailureReasonErrorKey: message as Any]
        }
        else
        {
            return [NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: response.statusCode)]
        }
    }
}
