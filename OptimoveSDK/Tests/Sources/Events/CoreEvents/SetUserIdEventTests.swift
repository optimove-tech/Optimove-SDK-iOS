//  Copyright © 2019 Optimove. All rights reserved.

@testable import OptimoveSDK
import XCTest

class SetUserIdEventTests: XCTestCase {
    func test_event_name() {
        // given
        let originalVistorId = "originalVistorId"
        let userId = "userId"
        let updateVisitorId = "updateVisitorId"

        // when
        let event = SetUserIdEvent(originalVistorId: originalVistorId, userId: userId, updateVisitorId: updateVisitorId)

        // then
        XCTAssert(event.name == SetUserIdEvent.Constants.name)
    }

    func test_event_parameters() {
        // given
        let originalVistorId = "originalVistorId"
        let userId = "userId"
        let updateVisitorId = "updateVisitorId"

        // when
        let event = SetUserIdEvent(originalVistorId: originalVistorId, userId: userId, updateVisitorId: updateVisitorId)

        // then
        XCTAssert(event.context[SetUserIdEvent.Constants.Key.originalVistorId] as? String == originalVistorId)
        XCTAssert(event.context[SetUserIdEvent.Constants.Key.userId] as? String == userId)
        XCTAssert(event.context[SetUserIdEvent.Constants.Key.updatedVisitorId] as? String == updateVisitorId)
    }
}
