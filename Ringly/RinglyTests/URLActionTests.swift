@testable import Ringly
import Nimble
import XCTest

class URLActionTests: XCTestCase
{
    // MARK: - Multi
    func testMultiIncludesValueURLsAndDropsInvalidURLs()
    {
        let URL1 = URL(string: "com.ringly.ringly://developer-mode/enable")!
        let URL2 = URL(string: "com.ringly.ringly://reset-password/token")!
        let URL3 = URL(string: "ringly://invalid")!

        var multiComponents = URLComponents(string: "com.ringly.ringly://multi")!
        multiComponents.queryItems = [
            URLQueryItem(name: "", value: URL1.absoluteString),
            URLQueryItem(name: "a", value: URL2.absoluteString),
            URLQueryItem(name: "a", value: URL3.absoluteString)
        ]

        let multiURL = multiComponents.url!

        expect(URLAction(url: multiURL))
            == .multi([.developerMode(enable: true), .resetPassword(token: "token")])
    }

    // MARK: - DFU
    func testDFUParsesSingleHardwareVersion()
    {
        expect(URLAction(url: URL(string: "com.ringly.ringly://dfu?hardware=V00&application=1.5.0")!))
            == .dfu(hardware: ["V00"], application: "1.5.0")
    }

    func testDFUParsesMultipleHardwareVersions()
    {
        // multiple hardware versions
        expect(URLAction(url: URL(string: "com.ringly.ringly://dfu?hardware=V00&hardware=V01&application=1.5.0")!))
            == .dfu(hardware: ["V00", "V01"], application: "1.5.0")
    }

    func testDFUFailsWithoutHardwareVersion()
    {
        expect(URLAction(url: URL(string: "com.ringly.ringly://dfu?application=1.5.0")!)).to(beNil())
    }

    func testDFUFailsWithoutApplicationVersion()
    {
        expect(URLAction(url: URL(string: "com.ringly.ringly://dfu?hardware=V00")!)).to(beNil())
    }

    // MARK: - Reset Password
    func testResetPasswordFailsWithoutToken()
    {
        expect(URLAction(url: URL(string: "com.ringly.ringly://reset-password")!)).to(beNil())
    }

    func testResetPasswordParsesToken()
    {
        expect(URLAction(url: URL(string: "com.ringly.ringly://reset-password/token")!))
            == .resetPassword(token: "token")
    }

    func testResetPasswordUniversalLinkFailsWithoutToken()
    {
        expect(URLAction(universalLinkURL: URL(string: "https://ringly.com/users/reset-password")!)).to(beNil())
    }

    func testResetPasswordUniversalLinkParsesToken()
    {
        expect(URLAction(universalLinkURL: URL(string: "https://ringly.com/users/reset-password/token")!))
            == .resetPassword(token: "token")
    }

    // MARK: - Collect Diagnostic Data
    func testCollectDiagnosticDataParsesWithoutReference()
    {
        expect(URLAction(url: URL(string: "com.ringly.ringly://collect-diagnostic-data")!))
            == .collectDiagnosticData(queryItems: [])
    }

    func testCollectDiagnosticDataParsesWithReference()
    {
        expect(URLAction(url: URL(string: "com.ringly.ringly://collect-diagnostic-data?reference=foo")!))
            == .collectDiagnosticData(queryItems: [URLQueryItem.init(name: "reference", value: "foo")])
    }

    func testCollectDiagnosticDataUniversalLinkParsesWithoutReference()
    {
        expect(URLAction(universalLinkURL: URL(string: "https://explore.ringly.com/diagnostic")!))
            == .collectDiagnosticData(queryItems: [])
    }

    func testCollectDiagnosticDataUniversalLinkParsesWithReference()
    {
        expect(URLAction(universalLinkURL: URL(string: "https://explore.ringly.com/diagnostic?reference=foo")!))
            == .collectDiagnosticData(queryItems: [URLQueryItem.init(name: "reference", value: "foo")])
    }

    // MARK: - Developer Mode
    func testDeveloperModeFailsWithoutSetting()
    {
        expect(URLAction(url: URL(string: "com.ringly.ringly://developer-mode")!)).to(beNil())
    }

    func testDeveloperModeParsesEnable()
    {
        expect(URLAction(url: URL(string: "com.ringly.ringly://developer-mode/enable")!))
            == .developerMode(enable: true)
    }

    func testDeveloperModeParsesDisable()
    {
        expect(URLAction(url: URL(string: "com.ringly.ringly://developer-mode/disable")!))
            == .developerMode(enable: false)
    }

    // MARK: - Review
    func testReview()
    {
        expect(URLAction(url: URL(string: "com.ringly.ringly://review")!)) == .review
    }

    // MARK: - Invalid
    func testInvalidEndpoint()
    {
        expect(URLAction(url: URL(string: "com.ringly.ringly://invalid")!)).to(beNil())
    }

    func testInvalidScheme()
    {
        expect(URLAction(url: URL(string: "ringly://ab/enable/1234")!)).to(beNil())
    }

    func testInvalidUniversalLink()
    {
        expect(URLAction(universalLinkURL: URL(string: "https://ringly.com/not/a/link")!)).to(beNil())
    }
}
