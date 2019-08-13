// Copiright 2019 Optimove

import XCTest
@testable import OptimoveSDK

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
        XCTAssert(event.parameters[SetUserIdEvent.Constants.Key.originalVistorId] as? String == originalVistorId)
        XCTAssert(event.parameters[SetUserIdEvent.Constants.Key.realtimeUserId] as? String == userId)
        XCTAssert(event.parameters[SetUserIdEvent.Constants.Key.updatedVisitorId] as? String == updateVisitorId)
    }

}
