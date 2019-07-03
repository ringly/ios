@testable import RinglyAPI
import Nimble
import XCTest

final class ReviewRequestTests: XCTestCase
{
    func testPositiveNoFeedback()
    {
        expect(ReviewRequest(rating: .positive).request(for: baseURL))
            == URLRequest(
                url: URL(string: "users/app-review", relativeTo: baseURL)!,
                method: "POST",
                json: [
                    "rating": 1,
                    "feedback": NSNull()
                ]
            )
    }

    func testNeutralNoFeedback()
    {
        expect(ReviewRequest(rating: .neutral).request(for: baseURL))
            == URLRequest(
                url: URL(string: "users/app-review", relativeTo: baseURL)!,
                method: "POST",
                json: [
                    "rating": 0,
                    "feedback": NSNull()
                ]
            )
    }

    func testNegativeNoFeedback()
    {
        expect(ReviewRequest(rating: .positive).request(for: baseURL))
            == URLRequest(
                url: URL(string: "users/app-review", relativeTo: baseURL)!,
                method: "POST",
                json: [
                    "rating": -1,
                    "feedback": NSNull()
                ]
            )
    }

    func testPositiveWithFeedback()
    {
        expect(ReviewRequest(rating: .positive, feedback: "test").request(for: baseURL))
            == URLRequest(
                url: URL(string: "users/app-review", relativeTo: baseURL)!,
                method: "POST",
                json: [
                    "rating": 1,
                    "feedback": "test"
                ]
            )
    }

    func testNeutralWithFeedback()
    {
        expect(ReviewRequest(rating: .neutral, feedback: "test").request(for: baseURL))
            == URLRequest(
                url: URL(string: "users/app-review", relativeTo: baseURL)!,
                method: "POST",
                json: [
                    "rating": 0,
                    "feedback": "test"
                ]
            )
    }

    func testNegativeWithFeedback()
    {
        expect(ReviewRequest(rating: .positive, feedback: "test").request(for: baseURL))
            == URLRequest(
                url: URL(string: "users/app-review", relativeTo: baseURL)!,
                method: "POST",
                json: [
                    "rating": -1,
                    "feedback": "test"
                ]
            )
    }
}

private let baseURL = URL(string: "https://test.com/")!

extension URLRequest
{
    init(url: URL, method: String, body: Data, headers: [String:String])
    {
        self.init(url: url)
        self.httpMethod = method
        self.httpBody = body
        self.allHTTPHeaderFields = headers
    }

    init(url: URL, method: String, json: Any, headers: [String:String] = ["Content-Type": "application/json"])
    {
        self.init(
            url: url,
            method: method,
            body: try! JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions()),
            headers: headers
        )
    }
}
