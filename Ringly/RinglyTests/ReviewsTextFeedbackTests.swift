@testable import Ringly
import XCTest

final class ReviewsTextFeedbackTests: XCTestCase
{
    func testPositiveNilTextEncode()
    {
        XCTAssertEqual(
            try? ReviewsTextFeedback.decode(ReviewsTextFeedback(feedback: .positive, text: nil).encoded),
            ReviewsTextFeedback(feedback: .positive, text: nil)
        )
    }

    func testNegativeNilTextEncode()
    {
        XCTAssertEqual(
            try? ReviewsTextFeedback.decode(ReviewsTextFeedback(feedback: .negative, text: nil).encoded),
            ReviewsTextFeedback(feedback: .negative, text: nil)
        )
    }

    func testPositiveTextEncode()
    {
        XCTAssertEqual(
            try? ReviewsTextFeedback.decode(ReviewsTextFeedback(feedback: .positive, text: "test").encoded),
            ReviewsTextFeedback(feedback: .positive, text: "test")
        )
    }

    func testNegativeTextEncode()
    {
        XCTAssertEqual(
            try? ReviewsTextFeedback.decode(ReviewsTextFeedback(feedback: .negative, text: "test").encoded),
            ReviewsTextFeedback(feedback: .negative, text: "test")
        )
    }
}
