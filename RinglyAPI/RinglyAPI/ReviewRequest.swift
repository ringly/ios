
// MARK: - Structure

/// Allows the user to provide a review of the app.
public struct ReviewRequest
{
    // MARK: - Initialization

    /// Initializes a review endpoint.
    ///
    /// - Parameters:
    ///   - rating: The user's rating of the app.
    ///   - feedback: The user's (optional) feedback. The default value is `nil`.
    public init(rating: Rating, feedback: String? = nil)
    {
        self.rating = rating
        self.feedback = feedback
    }

    // MARK: - Rating

    /// Enumerates the ratings that the user may give to the app.
    public enum Rating: Int
    {
        /// The user has had a negative experience.
        case negative = -1

        /// The user has had a neutral experience.
        case neutral = 0

        /// The user has had a positive experience.
        case positive = 1
    }

    /// The user's rating of the app.
    public let rating: Rating

    // MARK: - Feedback

    /// The user's (optional) feedback.
    public let feedback: String?
}

// MARK: - Request
extension ReviewRequest: RequestProviding
{
    public func request(for baseURL: URL) -> URLRequest?
    {
        return URLRequest(
            method: .post,
            baseURL: baseURL,
            relativeURLString: "users/app-review",
            jsonBody: [
                "rating": rating.rawValue,
                "feedback": feedback?.truncate(utf8: 1000) as Any? ?? NSNull()
            ]
        )
    }
}

// MARK: - String Extensions
extension String
{
    /// Truncates a string to under the specified number of UTF-8 characters.
    ///
    /// - Parameter length: The maximum UTF-8 length of the string.
    internal func truncate(utf8 length: Int) -> String
    {
        let utf8 = self.utf8

        if utf8.count > length
        {
            var sequence = utf8.dropLast(utf8.count - length)

            while sequence.count > 0
            {
                if let string = String(sequence)
                {
                    return string
                }

                sequence = sequence.dropLast()
            }

            return ""
        }
        else
        {
            return self
        }
    }
}
