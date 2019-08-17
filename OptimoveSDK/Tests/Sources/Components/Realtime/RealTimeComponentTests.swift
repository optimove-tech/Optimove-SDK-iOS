//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import OptimoveCore
@testable import OptimoveSDK

class RealTimeComponentTests: XCTestCase {

    var realTime: RealTime!
    var storage: MockOptimoveStorage!
    var networking: MockRealTimeNetworking!
    var warehouseProvider: EventsConfigWarehouseProvider!
    var warehouse: StubOptimoveEventConfigsWarehouse!
    var deviceStateMonitor: StubOptimoveDeviceStateMonitor!
    var handler: RealTimeHanlderAssertionProxy!
    var dateProvider: MockDateTimeProvider!

    override func setUp() {
        storage = MockOptimoveStorage()
        networking = MockRealTimeNetworking()
        deviceStateMonitor = StubOptimoveDeviceStateMonitor()
        warehouseProvider = EventsConfigWarehouseProvider()
        warehouse = StubOptimoveEventConfigsWarehouse()
        handler = RealTimeHanlderAssertionProxy(
            target: RealTimeHanlderImpl(storage: storage)
        )
        dateProvider = MockDateTimeProvider()
        realTime = RealTime(
            configuration: ConfigurationFixture.build().realtime,
            storage: storage,
            networking: networking,
            warehouse: warehouseProvider,
            deviceStateMonitor: deviceStateMonitor,
            eventBuilder: RealTimeEventBuilder(
                storage: storage
            ),
            handler: handler,
            coreEventFactory: CoreEventFactoryImpl(
                storage: storage,
                dateTimeProvider: dateProvider
            )
        )
        warehouseProvider.setWarehouse(warehouse)
        // FIXME: `performInitializationOperations()` should be called from a related test.
        realTime.performInitializationOperations()
    }

    private func prefilledStorage() {
        storage.customerID = StubVariables.customerID
        storage.visitorID = StubVariables.visitorID
        storage.userEmail = StubVariables.userEmail
        storage.initialVisitorId = StubVariables.initialVisitorId
    }

// MARK: - User Identifier

    func test_that_realtimeEvent_has_a_correct_customerID() {
        // given
        let customerID = "customerID"
        storage[.customerID] = customerID

        // then
        let expect = expectation(description: "Event was not generated.")
        networking.assertFunction = { (event) -> Result<String, Error> in
            XCTAssert(event.cid == customerID,
                      "Expected 'cid' value \(customerID). Actual \(String(describing: event.cid)).")
            XCTAssert(event.visitorId == nil,
                      "Expected 'visitorId' value nil. Actual \(String(describing: event.visitorId)).")
            expect.fulfill()
            return .success("")
        }

        // when
        realTime.reportEvent(event: StubEvent())
        waitForExpectations(timeout: expectationTimeout)
    }

    func test_that_realtimeEvent_has_a_correct_visitorId() {
        // given
        let visitorID = "visitorID"
        storage[.visitorID] = visitorID

        // then
        let expect = expectation(description: "Event was not generated.")
        networking.assertFunction = { (event) -> Result<String, Error> in
            XCTAssert(event.visitorId == visitorID,
                      "Expected 'visitorId' value \(visitorID). Actual \(String(describing: event.visitorId)).")
            XCTAssert(event.cid == nil,
                      "Expected 'cid' value nil. Actual \(String(describing: event.cid)).")
            expect.fulfill()
            return .success("")
        }

        // when
        realTime.reportEvent(event: StubEvent())
        waitForExpectations(timeout: expectationTimeout)
    }

    /// The event that is reported by name would become an RTE with its correct ID as defined in the config file.
    func test_that_realtimeEvent_has_a_correct_eventId() {
        // given
        prefilledStorage()

        // and setup config
        let eventId = 1000
        let parameterName = "parameterName"
        warehouse.config = EventsConfig(
            id: eventId,
            supportedOnOptitrack: true,
            supportedOnRealTime: true,
            parameters: [
                parameterName: Parameter(
                    type: StubVariables.string,
                    optiTrackDimensionId: 8,
                    optional: false
                )
            ]
        )

        // and setup event
        let stubEvent = StubEvent()
        stubEvent.name = parameterName

        // then
        let expect = expectation(description: "Event was not generated.")
        networking.assertFunction = { (event) -> Result<String, Error> in
            XCTAssert(event.eid == String(eventId),
                      "Expected event id value \(eventId). Actual \(event.eid).")
            expect.fulfill()
            return .success("")
        }

        // when
        realTime.reportEvent(event: stubEvent)
        waitForExpectations(timeout: expectationTimeout)
    }

    /// All parameters that exist in the OptimoveEvent are converted to Context inside the RTEvent
    func test_that_event_context_converted_successful() {
        // given
        prefilledStorage()

        // and
        let stubEvent = StubEvent()
        let parameters: [String: Any] = [
            "keyA": "value",
            "keyB": 1
        ]
        stubEvent.parameters = parameters

        // then
        let expect = expectation(description: "Event was not generated.")
        networking.assertFunction = { (event) -> Result<String, Error> in
            event.context.forEach { context in
                guard let value = parameters[context.key] else {
                    XCTFail("Cannot find expected value for key \(context.key)")
                    return
                }
                switch value {
                case let value as String:
                    XCTAssert(value == context.value as? String)
                case let value as Int:
                    XCTAssert(value == context.value as? Int)
                default:
                    XCTFail("Unsupported value: \(value.self)")
                }
            }
            expect.fulfill()
            return .success("")
        }

        // when
        realTime.reportEvent(event: stubEvent)
        waitForExpectations(timeout: expectationTimeout)
    }

    /// If the storage contains a firstTimeVisit timestamp, it will not change the RTEvent would contain it
    func test_that_first_time_visit_should_not_change_if_event_contains_it() {
        // given
        prefilledStorage()

        // and
        let timestamp = 123456
        storage[.firstVisitTimestamp] = timestamp

        // then
        let expect = expectation(description: "Event was not generated.")
        networking.assertFunction = { (event) -> Result<String, Error> in
            XCTAssert(String(timestamp) == event.firstVisitorDate)
            expect.fulfill()
            return .success("")
        }

        // when
        realTime.reportEvent(event: StubEvent())
        waitForExpectations(timeout: expectationTimeout)
    }


// MARK: - Sending Regular Events

    /// If an event is reported to the Realtime component and there is internet connection it must reach the HTTP client.
    func test_that_event_reach_networking() {
        // given
        prefilledStorage()
        let event = StubEvent()

        // then
        let expect = expectation(description: "Event was not generated.")
        networking.assertFunction = { (_) -> Result<String, Error> in
            expect.fulfill()
            return .success("")
        }

        // when
        realTime.reportEvent(event: event)
        waitForExpectations(timeout: expectationTimeout)
    }

    /// If an event is reported to the Realtime component and there is no internet connection, you will receive an indication that the event is skipped.
    func test_that_event_skipped_without_internet_connection() {
        // given
        deviceStateMonitor.state[.internet] = false

        // then
        let expect = expectation(description: "Event was not generated.")
        realTime.isAllowToSendReport { (isAllow) in
            XCTAssert(isAllow == false)
            expect.fulfill()
        }

        // when
        realTime.reportEvent(event: StubEvent())
        waitForExpectations(timeout: expectationTimeout)
    }

    /// If the storage contains a flag that SetUserID event failed when a regular event is reported the SetUserID event will be reported first
    func test_that_failed_userid_flag_will_trigger_setUserIdEvent_before_regularEvent() {
        // given
        prefilledStorage()
        storage[.realtimeSetUserIdFailed] = true
        let stubEvent = StubEvent()


        // then
        let userIdEventExpectation = expectation(description: "userIdEvent was not generated")
        let regularEventExpectation = expectation(description: "regularEvent was not generated")

        let isRegularEvent: (RealtimeEvent) -> Bool = { (event) in
            return stubEvent.isStubEvent(event)
        }
        let isUserIdEvent: (RealtimeEvent) -> Bool = { (event) in
            return event.context[SetUserIdEvent.Constants.Key.userId] as? String == StubVariables.customerID
        }
        networking.assertFunction = { (event) -> Result<String, Error> in
            if isRegularEvent(event) {
                regularEventExpectation.fulfill()
            }
            if isUserIdEvent(event) {
                userIdEventExpectation.fulfill()
            }
            return .success("")
        }

        // and
        let failedUserIdFlagExpectation = expectation(description: "failedUserIdFlag was not set")
        storage.assertFunction = { (value, key) in
            if key == .realtimeSetUserIdFailed, value as? Bool == false {
                failedUserIdFlagExpectation.fulfill()
            }
        }

        // when
        realTime.reportEvent(event: stubEvent)
        wait(for: [userIdEventExpectation, regularEventExpectation], timeout: expectationTimeout, enforceOrder: true)
        wait(for: [failedUserIdFlagExpectation], timeout: expectationTimeout)
    }

    /// If the storage contains a flag that SetUserEmail event failed when a regular event is reported the SetUserEmail event will be reported first
    func test_that_failed_userEmailFlag_will_trigger_setUserEmailEvent_before_regularEvent() {
        // given
        prefilledStorage()
        storage[.realtimeSetEmailFailed] = true
        let email = "aaa@bbb.com"
        storage[.userEmail] = email

        // and
        let stubEvent = StubEvent()

        // then
        let userEmailEventExpectation = expectation(description: "userEmailEvent was not generated")
        let regularEventExpectation = expectation(description: "regularEvent was not generated")

        let isRegularEvent: (RealtimeEvent) -> Bool = { (event) in
            return stubEvent.isStubEvent(event)
        }
        let isEmailEvent: (RealtimeEvent) -> Bool = { (event) in
            return event.context[SetUserEmailEvent.Constants.Key.email] as? String == email
        }
        networking.assertFunction = { (event) -> Result<String, Error> in
            if isRegularEvent(event) {
                regularEventExpectation.fulfill()
            }
            if isEmailEvent(event) {
                userEmailEventExpectation.fulfill()
            }
            return .success("")
        }

        // and
        let failedUserEmailFlagExpectation = expectation(description: "failedUserEmailFlag was not set")
        storage.assertFunction = { (value, key) in
            if key == .realtimeSetEmailFailed, value as? Bool == false {
                failedUserEmailFlagExpectation.fulfill()
            }
        }

        // when
        realTime.reportEvent(event: stubEvent)
        wait(for: [userEmailEventExpectation, regularEventExpectation], timeout: expectationTimeout, enforceOrder: true)
        wait(for: [failedUserEmailFlagExpectation], timeout: expectationTimeout)
    }

    /// If the storage contains a flag that SetUserID and SetUserEmail events failed, when a regular event is reported the SetUserId event will be reported first, then the SetUserEmail and finally the regular event.
    func test_FailedUserIdFlag_and_FailedUserEmailFlag_will_invoke_related_events_before_regular_one() {
        // given
        prefilledStorage()
        let email = "aaa@bbb.com"
        storage[.userEmail] = email
        let stubEvent = StubEvent()

        // and
        storage[.realtimeSetEmailFailed] = true
        storage[.realtimeSetUserIdFailed] = true

        // then
        let userIdEventExpectation = expectation(description: "userIdEvent was not generated")
        let userEmailEventExpectation = expectation(description: "userEmailEvent was not generated")
        let regularEventExpectation = expectation(description: "regularEvent was not generated")
        let isEmailEvent: (RealtimeEvent) -> Bool = { (event) in
            return event.context[SetUserEmailEvent.Constants.Key.email] as? String == email
        }
        let isRegularEvent: (RealtimeEvent) -> Bool = { (event) in
            return stubEvent.isStubEvent(event)
        }
        let isUserIdEvent: (RealtimeEvent) -> Bool = { (event) in
            return event.context[SetUserIdEvent.Constants.Key.userId] as? String == StubVariables.customerID
        }
        networking.assertFunction = { (event) -> Result<String, Error> in
            if isEmailEvent(event) {
                userEmailEventExpectation.fulfill()
            }
            if isRegularEvent(event) {
                regularEventExpectation.fulfill()
            }
            if isUserIdEvent(event) {
                userIdEventExpectation.fulfill()
            }
            return .success("")
        }

        // and
        let failedUserIdFlagExpectation = expectation(description: "failedUserId was not set")
        let failedUserEmailFlagExpectation = expectation(description: "failedUserEmailFlag was not set")
        storage.assertFunction = { (value, key) in
            if key == .realtimeSetUserIdFailed, value as? Bool == false {
                failedUserIdFlagExpectation.fulfill()
            }
            if key == .realtimeSetEmailFailed, value as? Bool == false {
                failedUserEmailFlagExpectation.fulfill()
            }
        }

        // when
        realTime.reportEvent(event: stubEvent)
        wait(for: [
            userIdEventExpectation,
            userEmailEventExpectation,
            regularEventExpectation
            ], timeout: expectationTimeout, enforceOrder: true)
        wait(for: [
            failedUserIdFlagExpectation,
            failedUserEmailFlagExpectation
            ], timeout: expectationTimeout, enforceOrder: true
        )
    }

    /// If more than 1 event is reported to the Realtime component and there is an internet connection, all the events reach the HTTP Client in the same order that they were reported.
    func test_more_than_1_event_report_order() {
        // given
        prefilledStorage()

        let key = "stub_name"

        let stubEventNameA = "stubEventNameA"
        let stubEventA = StubEvent()
        stubEventA.parameters[key] = stubEventNameA

        let stubEventNameB = "stubEventNameB"
        let stubEventB = StubEvent()
        stubEventB.parameters[key] = stubEventNameB

        let stubEventNameC = "stubEventNameC"
        let stubEventC = StubEvent()
        stubEventC.parameters[key] = stubEventNameC

        // then
        let stubEventAExpectation = expectation(description: "stubEventA was not generated")
        let stubEventBExpectation = expectation(description: "stubEventB was not generated")
        let stubEventCExpectation = expectation(description: "stubEventC was not generated")
        let isEventA: (RealtimeEvent) -> Bool = { (event) in
            return event.context[key] as? String == stubEventNameA
        }
        let isEventB: (RealtimeEvent) -> Bool = { (event) in
            return event.context[key] as? String == stubEventNameB
        }
        let isEventC: (RealtimeEvent) -> Bool = { (event) in
            return event.context[key] as? String == stubEventNameC
        }
        networking.assertFunction = { (event) -> Result<String, Error> in
            if isEventA(event) {
                stubEventAExpectation.fulfill()
            }
            if isEventB(event) {
                stubEventBExpectation.fulfill()
            }
            if isEventC(event) {
                stubEventCExpectation.fulfill()
            }
            return .success("")
        }

        // when
        realTime.reportEvent(event: stubEventA)
        realTime.reportEvent(event: stubEventB)
        realTime.reportEvent(event: stubEventC)
        wait(for: [
            stubEventAExpectation,
            stubEventBExpectation,
            stubEventCExpectation
            ], timeout: expectationTimeout, enforceOrder: true)
    }

    func test_decoration_invoke() {
        // given
        prefilledStorage()

        // and
        let event = StubEvent()

        // and
        warehouse.addParameters(
            [
                OptimoveKeys.AdditionalAttributesKeys.eventDeviceType: Parameter(
                    type: StubVariables.string,
                    optiTrackDimensionId: 8,
                    optional: false
                ),
                OptimoveKeys.AdditionalAttributesKeys.eventNativeMobile: Parameter(
                    type: StubVariables.string,
                    optiTrackDimensionId: 9,
                    optional: false
                ),
                OptimoveKeys.AdditionalAttributesKeys.eventOs: Parameter(
                    type: StubVariables.string,
                    optiTrackDimensionId: 10,
                    optional: false
                ),
                OptimoveKeys.AdditionalAttributesKeys.eventPlatform: Parameter(
                    type: StubVariables.string,
                    optiTrackDimensionId: 11,
                    optional: false
                )
            ]
        )

        // then
        let isDecoratedEvent: (RealtimeEvent) -> Bool = { (event) in
            return event.context[OptimoveKeys.AdditionalAttributesKeys.eventDeviceType] as? String == OptimoveKeys.AddtionalAttributesValues.eventDeviceType ||
                event.context[OptimoveKeys.AdditionalAttributesKeys.eventNativeMobile] as? Bool == OptimoveKeys.AddtionalAttributesValues.eventNativeMobile ||
                event.context[OptimoveKeys.AdditionalAttributesKeys.eventOs] as? String == OptimoveKeys.AddtionalAttributesValues.eventOs ||
                event.context[OptimoveKeys.AdditionalAttributesKeys.eventPlatform] as? String == OptimoveKeys.AddtionalAttributesValues.eventPlatform
        }
        let decorateExpectation = expectation(description: "Event was not decorated.")
        networking.assertFunction = { (event) -> Result<String, Error> in
            if isDecoratedEvent(event) {
                decorateExpectation.fulfill()
            }
            return .success("")
        }

        // when
        realTime.reportEvent(event: event)
        waitForExpectations(timeout: expectationTimeout)
    }

// MARK: - Sending SetUserID/SetEmail Events

    /// When a SetUserID event is reported and there is an internet connection, the storage flag for the failedSetUserId event should be false at the end of the flow.
    func test_SetUserIdEvent_reported_with_internet_expect_failedSetUserId_flag_false() {
        // given
        prefilledStorage()
        
        let event = SetUserIdEvent(
            originalVistorId: storage[.initialVisitorId]!,
            userId: storage[.customerID]!,
            updateVisitorId: storage[.visitorID]!
        )

        // then
        let expect = expectation(description: #function)
        storage.assertFunction = { (value, key) in
            if key == StorageKey.realtimeSetUserIdFailed, let value = value as? Bool {
                XCTAssert(value == false)
                expect.fulfill()
            }
        }
        
        // when
        realTime.reportEvent(event: event)
        waitForExpectations(timeout: expectationTimeout)
    }

    /// When a SetUserID event is reported and there is no internet connection, the storage flag for the failedSetUserId event should be true at the end of the flow.
    func test_SetUserIdEvent_reported_without_internet_expect_failedSetUserId_flag_true() {
        // given
        prefilledStorage()

        // and
        deviceStateMonitor.state[.internet] = false

        let event = SetUserIdEvent(
            originalVistorId: storage[.initialVisitorId]!,
            userId: storage[.customerID]!,
            updateVisitorId: storage[.visitorID]!
        )

        // then
        let expect = expectation(description: #function)
        storage.assertFunction = { (value, key) in
            if key == StorageKey.realtimeSetUserIdFailed, let value = value as? Bool {
                XCTAssert(value == true)
                expect.fulfill()
            }
        }

        // when
        realTime.reportEvent(event: event)
        waitForExpectations(timeout: expectationTimeout)
    }

    /// When a SetUserEmail event is reported and there is an internet connection, the storage flag for the failedSetUserEmail event should be false at the end of the flow.
    func test_SetUserEmail_reported_with_internet_expect_failedSetUserEmail_flag_false() {
        // given
        prefilledStorage()

        // and
        let event = SetUserEmailEvent(email: storage[.userEmail]!)

        // then
        let expect = expectation(description: #function)
        storage.assertFunction = { (value, key) in
            if key == StorageKey.realtimeSetEmailFailed, let value = value as? Bool {
                XCTAssert(value == false)
                expect.fulfill()
            }
        }

        // when
        realTime.reportEvent(event: event)
        waitForExpectations(timeout: expectationTimeout)
    }

    /// When a SetUserEmail event is reported and there is no internet connection, the storage flag for the failedSetUserEmail event should be true at the end of the flow.
    func test_SetUserEmail_reported_without_internet_expect_failedSetUserEmail_flag_true() {
        // given
        prefilledStorage()

        // and
        deviceStateMonitor.state[.internet] = false

        let event = SetUserEmailEvent(email: storage[.userEmail]!)

        // then
        let expect = expectation(description: #function)
        storage.assertFunction = { (value, key) in
            if key == StorageKey.realtimeSetEmailFailed, let value = value as? Bool {
                XCTAssert(value == true)
                expect.fulfill()
            }
        }

        // when
        realTime.reportEvent(event: event)
        waitForExpectations(timeout: expectationTimeout)
    }

    func test_report_screen_event() {
        // given
        prefilledStorage()

        let customURL = "customURL"
        let pageTitle = "pageTitle"
        let category = "category"

        // then
        let screenVisitEventExpectation = expectation(description: "screen visit event was not generated")
        let isScreenVisitEvent: (RealtimeEvent) -> Bool = { (event) in
            return event.context[PageVisitEvent.Constants.Key.customURL] as? String == customURL &&
            event.context[PageVisitEvent.Constants.Key.pageTitle] as? String == pageTitle &&
            event.context[PageVisitEvent.Constants.Key.category] as? String == category
        }
        networking.assertFunction = { (event) -> Result<String, Error> in
            if isScreenVisitEvent(event) {
                screenVisitEventExpectation.fulfill()
            }
            return .success("")
        }

        // when
        try! realTime.reportScreenEvent(customURL: customURL, pageTitle: pageTitle, category: category)
        waitForExpectations(timeout: expectationTimeout)
    }

    func test_report_without_customerID_and_visitorID() {
        // then
        let eventExpectation = expectation(description: "An error wasn't generated without cid and vid.")
        handler.handleOnCatchAssertFunc = { (eventType: RealTimeEventType, error: Error) in
            XCTAssert(eventType == .regular)
            XCTAssert(error.localizedDescription == RealTimeError.eitherCustomerOrVisitorIdIsNil.localizedDescription)
            eventExpectation.fulfill()
        }
        // when
        realTime.reportEvent(event: StubEvent())
        waitForExpectations(timeout: expectationTimeout)
    }
}

extension StubEvent {

    func isStubEvent(_ event: RealtimeEvent) -> Bool {
        return (event.context[Constnats.key] as? String) == Constnats.value
    }

}
