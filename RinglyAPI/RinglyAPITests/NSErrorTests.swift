@testable import RinglyAPI
import XCTest

class NSErrorTests: XCTestCase
{
    func testAPIErrorParsing()
    {
        let URL = Foundation.URL(string: "http://test.com")!
        let response = HTTPURLResponse(url: URL, statusCode: 400, httpVersion: nil, headerFields: nil)!

        // test only providing `message`
        let onlyMessage = NSError.userInfoForHTTPResponse(response, JSON: [
            "error": [
                "message": "test"
            ]
        ])

        XCTAssertEqual(onlyMessage[NSLocalizedDescriptionKey] as? String, nil)
        XCTAssertEqual(onlyMessage[NSLocalizedFailureReasonErrorKey] as? String, "test")

        // test providing all content
        let fullContent = NSError.userInfoForHTTPResponse(response, JSON: [
            "error": [
                "title": "test title",
                "body": "test body",
                "message": "test"
            ]
        ])

        XCTAssertEqual(fullContent[NSLocalizedDescriptionKey] as? String, "test title")
        XCTAssertEqual(fullContent[NSLocalizedFailureReasonErrorKey] as? String, "test body")

        // test not providing `title`
        let missingTitle = NSError.userInfoForHTTPResponse(response, JSON: [
            "error": [
                "body": "test body",
                "message": "test"
            ]
        ])

        XCTAssertEqual(missingTitle[NSLocalizedDescriptionKey] as? String, nil)
        XCTAssertEqual(missingTitle[NSLocalizedFailureReasonErrorKey] as? String, "test")

        // test not providing `body`
        let missingBody = NSError.userInfoForHTTPResponse(response, JSON: [
            "error": [
                "title": "test title",
                "message": "test"
            ]
        ])

        XCTAssertEqual(missingBody[NSLocalizedDescriptionKey] as? String, nil)
        XCTAssertEqual(missingBody[NSLocalizedFailureReasonErrorKey] as? String, "test")
    }
}
