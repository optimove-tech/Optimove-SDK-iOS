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

}
