@testable import Ringly
import XCTest

final class ReviewsStateCodableTests: XCTestCase
{
    func testDisplayAfter()
    {
        let date = Date()
        XCTAssertEqual(try? ReviewsState.decode(ReviewsState.displayAfter(date).encoded), .displayAfter(date))
    }

    func testDisplayed()
    {
        XCTAssertEqual(
            try? ReviewsState.decode(ReviewsState.displayed(version: "1.0").encoded),
            .displayed(version: "1.0")
        )
    }

    func testDisplayPrompt()
    {
        XCTAssertEqual(try? ReviewsState.decode(ReviewsState.display(.prompt).encoded), .display(.prompt))
    }

    func testDisplayPositiveFeedback()
    {
        XCTAssertEqual(
            try? ReviewsState.decode(ReviewsState.display(.feedback(.positive)).encoded),
            .display(.feedback(.positive))
        )
    }

    func testDisplayNegativeFeedback()
    {
        XCTAssertEqual(
            try? ReviewsState.decode(ReviewsState.display(.feedback(.negative)).encoded),
            .display(.feedback(.negative))
        )
    }

    func testDisplayNegativeCompletion()
    {
        XCTAssertEqual(
            try? ReviewsState.decode(ReviewsState.display(.negativeCompletion).encoded),
            .display(.negativeCompletion)
        )
    }
}

final class ReviewsDisplayCodableTests: XCTestCase
{
    func testPrompt()
    {
        XCTAssertEqual(try? ReviewsDisplay.decode(ReviewsDisplay.prompt.encoded), .prompt)
    }

    func testPositiveFeedback()
    {
        XCTAssertEqual(try? ReviewsDisplay.decode(ReviewsDisplay.feedback(.positive).encoded), .feedback(.positive))
    }

    func testNegativeFeedback()
    {
        XCTAssertEqual(try? ReviewsDisplay.decode(ReviewsDisplay.feedback(.negative).encoded), .feedback(.negative))
    }

    func testNegativeCompletion()
    {
        XCTAssertEqual(try? ReviewsDisplay.decode(ReviewsDisplay.negativeCompletion.encoded), .negativeCompletion)
    }
}
