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
        RunningFlagsIndication.setComponentRunningFlag(component: .optiTrack, state: true)

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
            dateTimeProvider: dateProvider,
            statisticService: statisticService,
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
        XCTAssertNoThrow(try optitrack.reportScreenEvent(screenTitle: screenTitle, screenPath: screenPath, category: category))
        wait(for: [trackViewExpectation, trackEventExpectation], timeout: expectationTimeout, enforceOrder: true)
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
        try! optitrack.report(event: stubEvent)
        wait(for: [trackEventExpectation], timeout: expectationTimeout, enforceOrder: true)
    }

    func test_dispatch_now() {
        // given
        RunningFlagsIndication.setComponentRunningFlag(component: .optiTrack, state: true)

        // then
        let trackDispatchExpectation = expectation(description: "dispatch now haven't been invoked.")
        tracker.dispatchAssertFunction = {
            trackDispatchExpectation.fulfill()
        }

        // when
        optitrack.dispatchNow()
        wait(for: [trackDispatchExpectation], timeout: expectationTimeout, enforceOrder: true)
    }

    func test_dispatch_now_if_component_disabled() {
        // given
        RunningFlagsIndication.setComponentRunningFlag(component: .optiTrack, state: false)

        // then
        let trackDispatchExpectation = expectation(description: "dispatch now event was invoked when component have been disabled.")
        trackDispatchExpectation.isInverted = true
        tracker.dispatchAssertFunction = {
            trackDispatchExpectation.fulfill()
        }

        // when
        optitrack.dispatchNow()
        wait(for: [trackDispatchExpectation], timeout: expectationTimeout, enforceOrder: true)
    }

    // MARK: - Tests for private methods

    func test_inject_to_tracker_visitorID() {
        // given
        let visitorID = StubVariables.visitorID

        // when
        storage.visitorID = visitorID
        optitrack.injectVisitorAndUserIdToMatomo()

        // then
        XCTAssertEqual(tracker.forcedVisitorId, visitorID,
                       "Expected value \(visitorID). Actual: \(String(describing: tracker.userId))")
    }

    func test_inject_to_tracker_customerID() {
        // given
        let customerID = StubVariables.customerID

        // when
        storage.customerID = customerID
        optitrack.injectVisitorAndUserIdToMatomo()

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
        optitrack.injectVisitorAndUserIdToMatomo()

        // then
        XCTAssert(tracker.userId == customerID,
                  "Expected value \(customerID). Actual: \(String(describing: tracker.userId))")
    }

    func test_reportIdfaIfAllowed() {
        // given

        // The required value `enableAdvertisingIdReport` set to true in `setUp` method.

        // then
        let trackEventExpectation = expectation(description: "IDFA events haven't been generated.")
        tracker.trackEventAssertFunction = { (event: TrackerEvent) -> Void in
            XCTAssert(event.action == SetAdvertisingIdEvent.Constants.name,
                      "Expect \(SetAdvertisingIdEvent.Constants.name). Actual \(event.action)")
            trackEventExpectation.fulfill()
        }

        // when
        optitrack.reportIdfaIfAllowed()
        wait(for: [trackEventExpectation], timeout: expectationTimeout)
    }

    func test_reportSdkVersion() {
        // given
        storage.configurationEndPoint = StubVariables.url
        storage.tenantToken = "tenantToken"
        storage.version = "version"

        // and
        let sdkVersionDimensions: [Int: String] = [
            8: MetaDataEvent.Constants.Key.sdkPlatform,
            9: MetaDataEvent.Constants.Key.sdkVersion,
            10: MetaDataEvent.Constants.Key.configFileURL,
            11: MetaDataEvent.Constants.Key.appNS
        ]

        let coreParameters: [Int: String] = [
            12: OptimoveKeys.AdditionalAttributesKeys.eventPlatform,
            13: OptimoveKeys.AdditionalAttributesKeys.eventDeviceType,
            14: OptimoveKeys.AdditionalAttributesKeys.eventOs,
            15: OptimoveKeys.AdditionalAttributesKeys.eventNativeMobile
        ]

        let expectedDimensions = sdkVersionDimensions.merging(coreParameters) { (current, _) in current }

        // then
        let trackEventExpectation = expectation(description: "SdkVersion report haven't expected count of dimensions.")
        trackEventExpectation.expectedFulfillmentCount = expectedDimensions.count
        tracker.trackEventAssertFunction = { (event: TrackerEvent) -> Void in
            let expected = MetaDataEvent.Constants.name
            XCTAssert(event.action == expected,
                      "Expect \(expected). Actual \(event.action)")
            expectedDimensions.forEach({ (expectedDimension) in
                event.dimensions.forEach({ (actualDimension) in
                    if expectedDimension.key == actualDimension.index {
                        trackEventExpectation.fulfill()
                    }
                })

            })
        }

        // when
        XCTAssertNoThrow(try optitrack.reportMetaData())
        wait(for: [trackEventExpectation], timeout: expectationTimeout, enforceOrder: true)
    }

    func test_reportOptInOutIfNeeded_optIn() {
        // given
        storage.isOptiTrackOptIn = false

        // then
        let trackEventExpectation = expectation(description: "OptIn events haven't been generated.")
        tracker.trackEventAssertFunction = { (event: TrackerEvent) -> Void in
            XCTAssert(event.action == OptimoveKeys.Configuration.optipushOptIn.rawValue,
                      "Expect \(OptimoveKeys.Configuration.optipushOptIn.rawValue). Actual \(event.action)")
            trackEventExpectation.fulfill()
        }

        let flagExpectation = expectation(description: "OptIn flag haven't been changed.")
        storage.assertFunction = { (value: Any?, key: StorageKey) -> Void in
            if key == .isOptiTrackOptIn {
                XCTAssert(value as? Bool == true,
                          "Expect true. Actual \(String(describing: value as? Bool))")
                flagExpectation.fulfill()
            }
        }

        // when
        optitrack.reportOptInOutIfNeeded()
        wait(for: [trackEventExpectation, flagExpectation], timeout: expectationTimeout)
    }

    func test_reportOptInOutIfNeeded_optOut() {
        // given
        storage.isOptiTrackOptIn = true
        deviceStateMonitor.state  = [
            .userNotification: false
        ]

        // then
        let trackEventExpectation = expectation(description: "OptIn events haven't been generated.")
        tracker.trackEventAssertFunction = { (event: TrackerEvent) -> Void in
            let expected = OptimoveKeys.Configuration.optipushOptOut.rawValue
            XCTAssert(event.action == expected,
                      "Expect \(expected). Actual \(event.action)")
            trackEventExpectation.fulfill()
        }

        let flagExpectation = expectation(description: "OptIn flag haven't been changed.")
        storage.assertFunction = { (value: Any?, key: StorageKey) -> Void in
            if key == .isOptiTrackOptIn {
                let expected = false
                XCTAssert(value as? Bool == expected,
                          "Expect \(String(expected)). Actual \(String(describing: value as? Bool))")
                flagExpectation.fulfill()
            }
        }

        // when
        optitrack.reportOptInOutIfNeeded()
        wait(for: [trackEventExpectation, flagExpectation], timeout: expectationTimeout)
    }

    func test_reportOptInOutIfNeeded_noNeed() {
        // given
        storage.isOptiTrackOptIn = true

        // then
        let trackEventExpectation = expectation(description: "OptIn events have been generated but should not")
        trackEventExpectation.isInverted = true
        tracker.trackEventAssertFunction = { (event: TrackerEvent) -> Void in
            trackEventExpectation.fulfill()
        }

        let flagExpectation = expectation(description: "OptIn flag have been changed but should not")
        flagExpectation.isInverted = true
        storage.assertFunction = { (value: Any?, key: StorageKey) -> Void in
            flagExpectation.fulfill()
        }

        // when
        optitrack.reportOptInOutIfNeeded()
        wait(for: [trackEventExpectation, flagExpectation], timeout: expectationTimeout)
    }

    func test_handleWillEnterForegroundNotification() {
        // given
        storage.visitorID = StubVariables.visitorID

        // and
        let now = Date()
        let throttlingThreshold = OptiTrack.Constants.AppOpen.throttlingThreshold
        let applicationOpenTime = now.addingTimeInterval(-(throttlingThreshold + 1)).timeIntervalSince1970

        // when
        statisticService.applicationOpenTime = applicationOpenTime
        dateProvider.mockedNow = now

        // then
        let trackEventExpectation = expectation(description: "track event haven't been generate.")
        tracker.trackEventAssertFunction = { (event: TrackerEvent) -> Void in
            XCTAssert(event.action == AppOpenEvent.Constants.name,
                      "Expect \(AppOpenEvent.Constants.name). Actual \(event.action)")
            trackEventExpectation.fulfill()
        }
        XCTAssertNoThrow(try optitrack.handleWillEnterForegroundNotification())
        wait(for: [trackEventExpectation], timeout: expectationTimeout, enforceOrder: true)
    }

    func test_willEnterForegroundNotification_action_throttled() {
        // given
        storage.visitorID = StubVariables.visitorID

        // and
        let now = Date()
        // Application was opened 10 sec ago.
        let applicationOpenTime = now.addingTimeInterval(-(10)).timeIntervalSince1970

        // when
        statisticService.applicationOpenTime = applicationOpenTime
        dateProvider.mockedNow = now

        // then
        let trackEventExpectation = expectation(description: "track event haven't been generate.")
        trackEventExpectation.isInverted = true
        tracker.trackEventAssertFunction = { (event: TrackerEvent) -> Void in
            XCTAssert(event.action == AppOpenEvent.Constants.name,
                      "Expect \(AppOpenEvent.Constants.name). Actual \(event.action)")
            trackEventExpectation.fulfill()
        }
        XCTAssertNoThrow(try optitrack.handleWillEnterForegroundNotification())
        wait(for: [trackEventExpectation], timeout: expectationTimeout, enforceOrder: true)
    }

    func test_reportPendingEvents() {
        // then
        let trackEventExpectation = expectation(description: "track dispath pending events haven't been generated.")
        tracker.dispathPendingEventsAssertFunction = {
            trackEventExpectation.fulfill()
        }

        // when
        optitrack.reportPendingEvents()
        wait(for: [trackEventExpectation], timeout: expectationTimeout, enforceOrder: true)
    }

    func test_reportAppOpen() {
        // given
        storage.customerID = StubVariables.customerID

        // then
        let trackEventExpectation = expectation(description: "track event haven't been generate.")
        tracker.trackEventAssertFunction = { (event: TrackerEvent) -> Void in
            XCTAssert(event.action == AppOpenEvent.Constants.name,
                      "Expect \(AppOpenEvent.Constants.name). Actual \(event.action)")
            trackEventExpectation.fulfill()
        }

        // when
        XCTAssertNoThrow(try optitrack.reportAppOpen())
        wait(for: [trackEventExpectation], timeout: expectationTimeout, enforceOrder: true)
    }
}
