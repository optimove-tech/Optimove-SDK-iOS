//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

class SetUserEmailEventTests: XCTestCase {

    func test_event_name() {
        // given
        let email = ""

        // when
        let event = SetUserEmailEvent(email: email)

        // then
        XCTAssert(event.name == SetUserEmailEvent.Constants.name)
    }

    func test_event_email() {
        // given
        let email = ""

        // when
        let event = SetUserEmailEvent(email: email)

        // then
        XCTAssert(event.parameters[SetUserEmailEvent.Constants.Key.email] as? String == email)
    }
}
