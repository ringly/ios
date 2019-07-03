@testable import Ringly
import Nimble
import XCTest

final class MailComposeErrorTests: XCTestCase
{
    fileprivate let error = MailComposeError(errorDescription: "Description", failureReason: "Failure Reason")

    func testLocalizedDescription()
    {
        expect((self.error as NSError).localizedDescription) == "Description"
    }

    func testLocalizedFailureReason()
    {
        expect((self.error as NSError).localizedFailureReason) == "Failure Reason"
    }
}
