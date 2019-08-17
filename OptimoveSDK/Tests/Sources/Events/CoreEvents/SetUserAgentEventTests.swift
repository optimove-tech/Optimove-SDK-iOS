//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

class SetUserAgentEventTests: XCTestCase {

    func test_event_name() {
        // given
        let userAgent = ""

        // when
        let event = SetUserAgent(userAgent: userAgent)

        // then
        XCTAssert(event.name == SetUserAgent.Constants.name)
    }

    func test_event_long_useragent() {
        // given
        let userAgentLenght = 600
        let userAgent = Array(repeating: "a", count: userAgentLenght).joined()
        let expectedParameterCount = (Float(userAgentLenght) / Float(SetUserAgent.Constants.userAgentSliceLenght)).rounded(.up)

        // when
        let event = SetUserAgent(userAgent: userAgent)

        // then
        XCTAssert(event.parameters.count == Int(expectedParameterCount))
    }

    func test_event_short_useragent() {
        // given
        let userAgentLenght = 100
        let userAgent = Array(repeating: "a", count: userAgentLenght).joined()
        let expectedParameterCount = (Float(userAgentLenght) / Float(SetUserAgent.Constants.userAgentSliceLenght)).rounded(.up)

        // when
        let event = SetUserAgent(userAgent: userAgent)

        // then
        XCTAssert(event.parameters.count == Int(expectedParameterCount))
    }

    func test_event_useragent_key_started_with_1() {
        // given
        let userAgentLenght = 100
        let userAgent = Array(repeating: "a", count: userAgentLenght).joined()

        // when
        let event = SetUserAgent(userAgent: userAgent)

        // then
        let first = event.parameters.first
        XCTAssert(first?.key == SetUserAgent.Constants.userAgentHeaderBase + String(1))
    }

}
