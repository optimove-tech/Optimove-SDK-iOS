//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import OptimoveCore
@testable import OptimoveSDK

class TriggeredNotificationOpenedTests: XCTestCase {

    func test_event_name() {
        // when
        let event = TriggeredNotificationOpened(
            bundleIdentifier: StubVariables.string,
            campaign: TriggeredNotificationCampaign(
                actionSerial: StubVariables.int,
                actionID: StubVariables.int,
                templateID: StubVariables.int,
                engagementID: nil
            )
        )

        // then
        XCTAssert(event.name == TriggeredNotificationOpened.Constants.name)
    }

    func test_event_parameters_visitor() {
        // given
        let bundleIdentifier = "bundleIdentifier"
        let actionSerial = 1
        let actionID = 2
        let templateID = 3
        let date = Date()

        // when
        let event = TriggeredNotificationOpened(
            bundleIdentifier: bundleIdentifier,
            campaign: TriggeredNotificationCampaign(
                actionSerial: actionSerial,
                actionID: actionID,
                templateID: templateID,
                engagementID: nil
            ),
            date: date
        )

        // then
        XCTAssert(event.context[TriggeredNotificationOpened.Constants.Key.appNS] as? String == bundleIdentifier)
        XCTAssert(event.context[TriggeredNotificationOpened.Constants.Key.actionSerial] as? Int == actionSerial)
        XCTAssert(event.context[TriggeredNotificationOpened.Constants.Key.actionID] as? Int == actionID)
        XCTAssert(event.context[TriggeredNotificationOpened.Constants.Key.templateID] as? Int == templateID)
        XCTAssert(event.context[TriggeredNotificationOpened.Constants.Key.timestamp] as? Int == Int(date.timeIntervalSince1970))
    }

}
