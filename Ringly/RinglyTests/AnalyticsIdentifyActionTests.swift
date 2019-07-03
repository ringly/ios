//
//  AnalyticsIdentifyActionTests.swift
//  Ringly
//
//  Created by Nate Stedman on 11/14/16.
//  Copyright © 2016 Ringly. All rights reserved.
//

@testable import Ringly
import XCTest

class AnalyticsIdentifyActionTests: XCTestCase
{
    func testCurrentWithNoPrevious()
    {
        XCTAssertEqual(
            AnalyticsIdentifyAction.actions(from: nil, to: "current"),
            [AnalyticsIdentifyAction.identify("current")]
        )
    }

    func testCurrentWithPrevious()
    {
        XCTAssertEqual(
            AnalyticsIdentifyAction.actions(from: "previous", to: "current"),
            [
                AnalyticsIdentifyAction.identify("current"),
                AnalyticsIdentifyAction.alias(identifier: "current", alias: "previous")
            ]
        )
    }

    func testNoCurrentWithNoPrevious()
    {
        XCTAssertEqual(AnalyticsIdentifyAction.actions(from: nil, to: nil), [.random])
    }

    func testNoCurrentWithPrevious()
    {
        XCTAssertEqual(AnalyticsIdentifyAction.actions(from: "previous", to: nil), [.random])
    }

    func testRedundantCurrent()
    {
        XCTAssertEqual(AnalyticsIdentifyAction.actions(from: "current", to: "current"), [.identify("current")])
    }
}
