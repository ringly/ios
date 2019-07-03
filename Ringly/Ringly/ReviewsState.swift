import Foundation
import RinglyAPI

// MARK: - State
enum ReviewsState: Equatable
{
    case displayAfter(Date)
    case display(ReviewsDisplay)
    case displayed(version: String)
}

extension ReviewsState
{
    // MARK: - State Creators
    static var displayedForCurrentVersion: ReviewsState
    {
        return .displayed(version: Bundle.main.version ?? "unknown")
    }

    // MARK: - Extracting Values

    /// The date associated with a `DisplayAfter` case.
    var displayAfterDate: Date?
    {
        switch self
        {
        case let .displayAfter(date):
            return date
        default:
            return nil
        }
    }

    /// The `ReviewsDisplay` associated with a `Display` case.
    var displayValue: ReviewsDisplay?
    {
        switch self
        {
        case let .display(display):
            return display
        default:
            return nil
        }
    }
}

extension ReviewsState: Coding
{
    // MARK: - Codable
    typealias Encoded = [String:Any]

    fileprivate static let displayAfterKey = "displayAfter"
    fileprivate static let displayKey = "display"
    fileprivate static let displayedKey = "displayed"

    static func decode(_ encoded: Encoded) throws -> ReviewsState
    {
        if let date = (try? NSKeyedUnarchiver.unarchiveObject(with: encoded.decode(displayAfterKey))) as? Date
        {
            return ReviewsState.displayAfter(date)
        }
        else if let any = encoded[displayKey]
        {
            return try ReviewsState.display(ReviewsDisplay.decode(any: any))
        }
        else
        {
            return try ReviewsState.displayed(version: encoded.decode(displayedKey))
        }
    }

    var encoded: Encoded
    {
        switch self
        {
        case let .displayAfter(date):
            return [ReviewsState.displayAfterKey: NSKeyedArchiver.archivedData(withRootObject: date) as AnyObject]
        case let .display(display):
            return [ReviewsState.displayKey: display.encoded as AnyObject]
        case let .displayed(version):
            return [ReviewsState.displayedKey: version as AnyObject]
        }
    }
}

func ==(lhs: ReviewsState, rhs: ReviewsState) -> Bool
{
    switch (lhs, rhs)
    {
    case let (.displayAfter(lhsDate), .displayAfter(rhsDate)):
        return lhsDate == rhsDate
    case let (.display(lhsDisplay), .display(rhsDisplay)):
        return lhsDisplay == rhsDisplay
    case let (.displayed(lhsVersion), .displayed(rhsVersion)):
        return lhsVersion == rhsVersion
    default:
        return false
    }
}

// MARK: - Display State

/// Determines which child view controller should be displayed in a reviews view controller.
enum ReviewsDisplay: Equatable
{
    /// Prompts the user to rate the app positively or negatively.
    case prompt

    /// Prompts the user to review the app in the App Store, or to provide direct feedback to Ringly support.
    case feedback(ReviewsFeedback)

    /// Thanks the user for providing negative feedback.
    case negativeCompletion
}

extension ReviewsDisplay: Coding
{
    typealias Encoded = [String:Any]

    fileprivate static let promptKey = "prompt"
    fileprivate static let feedbackKey = "feedback"
    fileprivate static let negativeCompletionKey = "negativeCompletion"

    static func decode(_ encoded: Encoded) throws -> ReviewsDisplay
    {
        if encoded[promptKey] != nil
        {
            return .prompt
        }
        else if encoded[negativeCompletionKey] != nil
        {
            return .negativeCompletion
        }
        else
        {
            let feedback: ReviewsFeedback = try encoded.decodeRaw(feedbackKey)
            return .feedback(feedback)
        }
    }

    var encoded: Encoded
    {
        switch self
        {
        case let .feedback(feedback):
            return [ReviewsDisplay.feedbackKey: feedback.rawValue as AnyObject]
        case .negativeCompletion:
            return [ReviewsDisplay.negativeCompletionKey: true as AnyObject]
        case .prompt:
            return [ReviewsDisplay.promptKey: true as AnyObject]
        }
    }
}

func ==(lhs: ReviewsDisplay, rhs: ReviewsDisplay) -> Bool
{
    switch (lhs, rhs)
    {
    case (.prompt, .prompt):
        return true
    case let (.feedback(lhsFeedback), .feedback(rhsFeedback)):
        return lhsFeedback == rhsFeedback
    case (.negativeCompletion, .negativeCompletion):
        return true
    default:
        return false
    }
}

// MARK: - Feedback
enum ReviewsFeedback: Int
{
    case positive = 1
    case negative = -1
}

extension ReviewsFeedback
{
    var endpointRating: ReviewRequest.Rating
    {
        switch self
        {
        case .positive:
            return .positive
        case .negative:
            return .negative
        }
    }
}

struct ReviewsTextFeedback: Equatable
{
    let feedback: ReviewsFeedback
    let text: String?
}

func ==(lhs: ReviewsTextFeedback, rhs: ReviewsTextFeedback) -> Bool
{
    return lhs.feedback == rhs.feedback && lhs.text == rhs.text
}

extension ReviewsTextFeedback
{
    var endpoint: ReviewRequest
    {
        return ReviewRequest(rating: feedback.endpointRating, feedback: text)
    }
}

extension ReviewsTextFeedback: Coding
{
    typealias Encoded = [String:Any]

    fileprivate static let feedbackKey = "feedback"
    fileprivate static let textKey = "text"

    var encoded: Encoded
    {
        return [
            ReviewsTextFeedback.feedbackKey: feedback.rawValue as AnyObject,
            ReviewsTextFeedback.textKey: text as AnyObject? ?? NSNull()
        ]
    }

    static func decode(_ encoded: Encoded) throws -> ReviewsTextFeedback
    {
        return try ReviewsTextFeedback(
            feedback: encoded.decodeRaw(feedbackKey),
            text: encoded[textKey] as? String
        )
    }
}
