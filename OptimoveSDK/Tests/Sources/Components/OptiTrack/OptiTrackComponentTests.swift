//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import OptimoveCore
@testable import OptimoveSDK

final class OptiTrackComponentTests: XCTestCase {

    var optitrack: OptiTrack!
    var tracker: MockTracker!
    var storage: MockOptimoveStorage!
    var deviceStateMonitor: StubOptimoveDeviceStateMonitor!
    var dateProvider: MockDateTimeProvider!
    var statisticService: MockStatisticService!

    override func setUp() {
        storage = MockOptimoveStorage()
        deviceStateMonitor = StubOptimoveDeviceStateMonitor()
        tracker = MockTracker()
        dateProvider = MockDateTimeProvider()
        statisticService = MockStatisticService()

        optitrack = OptiTrack(
            configuration: ConfigurationFixture.build().optitrack,
            deviceStateMonitor: deviceStateMonitor,
            storage: storage,
            coreEventFactory: CoreEventFactoryImpl(
                storage: storage,
                dateTimeProvider: dateProvider
            ),
            trackerFlagsBuilder: TrackerFlagsBuilder(
                storage: storage
            ),
            tracker: tracker
        )
    }

    override func tearDown() {
        storage.state = [:]
    }

    private func prefilledStorage() {
        storage.customerID = StubVariables.customerID
        storage.visitorID = StubVariables.visitorID
        storage.userEmail = StubVariables.userEmail
        storage.initialVisitorId = StubVariables.initialVisitorId
    }

    func test_screen_event_report() {
        // given
        let screenTitle = "screenTitle"
        let screenPath = "screenPath"
        let category = "category"

        // then
        let trackEventExpectation = expectation(description: "track event haven't been generated.")
        tracker.trackEventAssertFunction = { (event: TrackerEvent) -> Void in
            XCTAssert(event.action == PageVisitEvent.Constants.name,
                      "Expect \(PageVisitEvent.Constants.name). Actual \(event.action)")
            trackEventExpectation.fulfill()
        }

        let trackViewExpectation = expectation(description: "track view event haven't been generated.")
        let expectedURL = URL(string: "http://\(screenPath)")!
        tracker.trackViewAssertFunction = { (views: [String], url: URL?) -> Void in
            XCTAssert(views == [screenTitle],
                      "Expect \([screenTitle]). Actual \(views)")
            XCTAssert(url == expectedURL,
                      "Expect \(expectedURL). Actual \(String(describing: url))")
            trackViewExpectation.fulfill()
        }

        // when
        XCTAssertNoThrow(try optitrack.handleEventable(EventableOperationContext(.reportScreenEvent(customURL: screenPath, pageTitle: screenTitle, category: category))))
        wait(for: [trackViewExpectation, trackEventExpectation], timeout: defaultTimeout, enforceOrder: true)
    }

    func test_event_report() {
        // given
        let stubEvent = StubEvent()

        // then
        let trackEventExpectation = expectation(description: "track event haven't been generated.")
        tracker.trackEventAssertFunction = { (event: TrackerEvent) -> Void in
            XCTAssert(event.action == StubEvent.Constnats.name,
                      "Expect \(StubEvent.Constnats.name). Actual \(event.action)")
            trackEventExpectation.fulfill()
        }

        // when
        try! optitrack.handleEventable(EventableOperationContext(.report(event: stubEvent)))
        wait(for: [trackEventExpectation], timeout: defaultTimeout, enforceOrder: true)
    }

    func test_dispatch_now() {
        // then
        let trackDispatchExpectation = expectation(description: "dispatch now haven't been invoked.")
        tracker.dispatchAssertFunction = {
            trackDispatchExpectation.fulfill()
        }

        // when
        try! optitrack.handleEventable(EventableOperationContext(.dispatchNow))
        wait(for: [trackDispatchExpectation], timeout: defaultTimeout, enforceOrder: true)
    }

    // MARK: - Tests for private methods

    func test_inject_to_tracker_visitorID() {
        // given
        let visitorID = StubVariables.visitorID

        // when
        storage.visitorID = visitorID
        optitrack.syncVisitorAndUserIdToMatomo()

        // then
        XCTAssertEqual(tracker.forcedVisitorId, visitorID,
                       "Expected value \(visitorID). Actual: \(String(describing: tracker.userId))")
    }

    func test_inject_to_tracker_customerID() {
        // given
        let customerID = StubVariables.customerID

        // when
        storage.customerID = customerID
        optitrack.syncVisitorAndUserIdToMatomo()

        // then
        XCTAssert(tracker.userId == customerID,
                  "Expected value \(customerID). Actual: \(String(describing: tracker.userId))")
    }

    func test_inject_to_tracker_visitorID_has_lower_priority_than_customerID() {
        // given
        let visitorID = StubVariables.visitorID
        let customerID = StubVariables.customerID

        // when
        storage.visitorID = visitorID
        storage.customerID = customerID
        optitrack.syncVisitorAndUserIdToMatomo()

        // then
        XCTAssert(tracker.userId == customerID,
                  "Expected value \(customerID). Actual: \(String(describing: tracker.userId))")
    }

}
