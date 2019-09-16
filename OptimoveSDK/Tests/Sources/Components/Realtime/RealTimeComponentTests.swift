//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import OptimoveCore
@testable import OptimoveSDK

class RealTimeComponentTests: XCTestCase {

    var realTime: RealTime!
    var storage: MockOptimoveStorage!
    var networking: MockRealTimeNetworking!
    var handler: RealTimeHanlderAssertionProxy!
    var dateProvider: MockDateTimeProvider!

    override func setUp() {
        storage = MockOptimoveStorage()
        networking = MockRealTimeNetworking()
        handler = RealTimeHanlderAssertionProxy(
            target: RealTimeHanlderImpl(storage: storage)
        )
        dateProvider = MockDateTimeProvider()
        realTime = RealTime(
            configuration: ConfigurationFixture.build().realtime,
            storage: storage,
            networking: networking,
            eventBuilder: RealTimeEventBuilder(
                storage: storage
            ),
            handler: handler,
            coreEventFactory: CoreEventFactoryImpl(
                storage: storage,
                dateTimeProvider: dateProvider
            )
        )
    }

    private func prefilledVisitorStorage() {
        storage.visitorID = StubVariables.visitorID
        storage.initialVisitorId = StubVariables.initialVisitorId
    }


// MARK: - User Identifier

    func test_that_realtimeEvent_has_a_correct_customerID() {
        // given
        prefilledVisitorStorage()

        // and
        let customerID = StubVariables.customerID
        storage.customerID = customerID
        storage.realtimeLastSuccessfulSentUserID = customerID

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
        try! realTime.reportEvent(event: StubEvent())
        waitForExpectations(timeout: realtimeTimeout)
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
        try! realTime.reportEvent(event: StubEvent())
        waitForExpectations(timeout: realtimeTimeout)
    }

    /// The event that is reported by name would become an RTE with its correct ID as defined in the config file.
    func test_that_realtimeEvent_has_a_correct_eventId() {
        // given
        prefilledVisitorStorage()
        let stubEvent = StubEvent()

        // then
        let expect = expectation(description: "Event was not generated.")
        networking.assertFunction = { (event) -> Result<String, Error> in
            XCTAssertEqual(event.eid, String(StubEvent.Constnats.id))
            expect.fulfill()
            return .success("")
        }

        // when
        try! realTime.reportEvent(event: stubEvent)
        waitForExpectations(timeout: realtimeTimeout)
    }

    /// All parameters that exist in the OptimoveEvent are converted to Context inside the RTEvent
    func test_that_event_context_converted_successful() {
        // given
        prefilledVisitorStorage()

        // and
        let stubEvent = StubEvent()

        // then
        let expect = expectation(description: "Event was not generated.")
        networking.assertFunction = { (event) -> Result<String, Error> in
            stubEvent.parameters.forEach { parameter in
                guard let value = event.context[parameter.key] else {
                    XCTFail("Cannot find expected value for key \(parameter.key)")
                    return
                }
                switch value {
                case let value as String:
                    XCTAssert(value == parameter.value as? String)
                case let value as Int:
                    XCTAssert(value == parameter.value as? Int)
                default:
                    XCTFail("Unsupported value: \(value.self)")
                }
            }
            expect.fulfill()
            return .success("")
        }

        // when
        try! realTime.reportEvent(event: stubEvent)
        waitForExpectations(timeout: realtimeTimeout)
    }

    /// If the storage contains a firstTimeVisit timestamp, it will not change the RTEvent would contain it
    func test_that_first_time_visit_should_not_change_if_event_contains_it() {
        // given
        prefilledVisitorStorage()

        // and
        let timestamp = 123_456
        storage[.firstVisitTimestamp] = timestamp

        // then
        let expect = expectation(description: "Event was not generated.")
        networking.assertFunction = { (event) -> Result<String, Error> in
            XCTAssert(String(timestamp) == event.firstVisitorDate)
            expect.fulfill()
            return .success("")
        }

        // when
        try! realTime.reportEvent(event: StubEvent())
        waitForExpectations(timeout: realtimeTimeout)
    }

// MARK: - Sending Regular Events

    /// If an event is reported to the Realtime component and there is internet connection it must reach the HTTP client.
    func test_that_event_reach_networking() {
        // given
        prefilledVisitorStorage()
        let event = StubEvent()

        // then
        let expect = expectation(description: "Event was not generated.")
        networking.assertFunction = { (_) -> Result<String, Error> in
            expect.fulfill()
            return .success("")
        }

        // when
        try! realTime.reportEvent(event: event)
        waitForExpectations(timeout: realtimeTimeout)
    }

    /// If the storage contains a flag that SetUserID event failed when a regular event is reported the SetUserID event will be reported first
    func test_that_failed_userid_flag_will_trigger_setUserIdEvent_before_regularEvent() {
        // given
        prefilledVisitorStorage()
        storage.realtimeLastSuccessfulSentUserID = nil
        let customerID = "abc"
        storage.customerID = customerID
        let stubEvent = StubEvent()

        // then
        let userIdEventExpectation = expectation(description: "userIdEvent was not generated")
        let regularEventExpectation = expectation(description: "regularEvent was not generated")

        let isRegularEvent: (RealtimeEvent) -> Bool = { (event) in
            return stubEvent.isStubEvent(event)
        }
        let isUserIdEvent: (RealtimeEvent) -> Bool = { (event) in
            return event.context[SetUserIdEvent.Constants.Key.userId] as? String == customerID
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
        let lastSuccessfulUserIdValueExpectation = expectation(description: "failedUserIdFlag was not set")
        storage.assertFunction = { (value, key) in
            if key == .realtimeLastSuccessfulSentUserID, (value as? String) == customerID {
                lastSuccessfulUserIdValueExpectation.fulfill()
            }
        }

        // when
        try! realTime.reportEvent(event: stubEvent)
        wait(for: [userIdEventExpectation, regularEventExpectation], timeout: realtimeTimeout, enforceOrder: true)
        wait(for: [lastSuccessfulUserIdValueExpectation], timeout: realtimeTimeout)
    }

    /// If the storage contains a flag that SetUserEmail event failed when a regular event is reported the SetUserEmail event will be reported first
    func test_that_failed_userEmailFlag_will_trigger_setUserEmailEvent_before_regularEvent() {
        // given
        prefilledVisitorStorage()
        storage.realtimeLastSuccessfulSentEmail = nil
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
            if key == .realtimeLastSuccessfulSentEmail, (value as? String) == email {
                failedUserEmailFlagExpectation.fulfill()
            }
        }

        // when
        try! realTime.reportEvent(event: stubEvent)
        wait(for: [userEmailEventExpectation, regularEventExpectation], timeout: realtimeTimeout, enforceOrder: true)
        wait(for: [failedUserEmailFlagExpectation], timeout: realtimeTimeout)
    }

    /// If the storage contains a flag that SetUserID and SetUserEmail events failed, when a regular event is reported the SetUserId event will be reported first, then the SetUserEmail and finally the regular event.
    func test_FailedUserIdFlag_and_FailedUserEmailFlag_will_invoke_related_events_before_regular_one() {
        // given
        prefilledVisitorStorage()
        let email = "aaa@bbb.com"
        storage.userEmail = email
        let customerID = "abc"
        storage.customerID = customerID
        let stubEvent = StubEvent()

        // and
        storage.realtimeLastSuccessfulSentUserID = nil
        storage.realtimeLastSuccessfulSentEmail = nil

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
            return event.context[SetUserIdEvent.Constants.Key.userId] as? String == customerID
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
        let lastSuccessfulUserIdExpectation = expectation(description: "failedUserId was not set")
        let lastSuccessfulUserEmailExpectation = expectation(description: "failedUserEmailFlag was not set")
        storage.assertFunction = { (value, key) in
            if key == .realtimeLastSuccessfulSentUserID, value as? String == customerID {
                lastSuccessfulUserIdExpectation.fulfill()
            }
            if key == .realtimeLastSuccessfulSentEmail, value as? String == email {
                lastSuccessfulUserEmailExpectation.fulfill()
            }
        }

        // when
        try! realTime.reportEvent(event: stubEvent)
        wait(for: [
            userIdEventExpectation,
            userEmailEventExpectation,
            regularEventExpectation
        ], timeout: realtimeTimeout, enforceOrder: true)
        wait(for: [
            lastSuccessfulUserIdExpectation,
            lastSuccessfulUserEmailExpectation
        ], timeout: realtimeTimeout, enforceOrder: true
        )
    }

    /// If more than 1 event is reported to the Realtime component and there is an internet connection, all the events reach the HTTP Client in the same order that they were reported.
    func test_more_than_1_event_report_order() {
        // given
        prefilledVisitorStorage()

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
        try! realTime.reportEvent(event: stubEventA)
        try! realTime.reportEvent(event: stubEventB)
        try! realTime.reportEvent(event: stubEventC)
        wait(for: [
            stubEventAExpectation,
            stubEventBExpectation,
            stubEventCExpectation
        ], timeout: realtimeTimeout, enforceOrder: true)
    }

    func test_decoration_invoke() {
        // given
        prefilledVisitorStorage()

        // and
        let event = StubEvent()

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
        try! realTime.reportEvent(event: event)
        waitForExpectations(timeout: realtimeTimeout)
    }

// MARK: - Sending SetUserID/SetEmail Events

    /// When a SetUserID event is reported and there is an internet connection,
    /// the storage flag for the failedSetUserId event should be false at the end of the flow.
    func test_SetUserIdEvent_reported_with_internet_expect_correct_lastSuccessfulValue() {
        // given
        prefilledVisitorStorage()

        let customerID = StubVariables.customerID
        storage.customerID = customerID

        let event = SetUserIdEvent(
            originalVistorId: storage.initialVisitorId!,
            userId: storage.customerID!,
            updateVisitorId: storage.visitorID!
        )

        // then
        let expect = expectation(description: "Last successful sent user id was not generated.")
        storage.assertFunction = { (value, key) in
            if key == StorageKey.realtimeLastSuccessfulSentUserID {
                XCTAssert(value as? String == customerID)
                expect.fulfill()
            }
        }

        // when
        try! realTime.reportEvent(event: event)
        waitForExpectations(timeout: realtimeTimeout)
    }

    /// When a SetUserID event is reported and there is no internet connection,
    /// the storage value for the realtimeLastSuccessfulSentUserID should be a correct one at the end of the flow.
    func test_SetUserIdEvent_reported_without_internet_expect_correct_lastSuccessfulValue() {
        // given
        prefilledVisitorStorage()

        // and
        let customerID = StubVariables.customerID
        storage.customerID = customerID
        storage.realtimeLastSuccessfulSentUserID = nil

        // and
        let event = SetUserIdEvent(
            originalVistorId: storage.initialVisitorId!,
            userId: storage.customerID!,
            updateVisitorId: storage.visitorID!
        )

        // and
        networking.assertFunction = { event in
            return .failure(NetworkError.requestFailed)
        }

        // then
        let lastSuccessfulValueExpectation = expectation(description: "Last successful user id was generated.")
        lastSuccessfulValueExpectation.isInverted.toggle()
        storage.assertFunction = { (_, key) in
            if key == StorageKey.realtimeLastSuccessfulSentUserID {
                lastSuccessfulValueExpectation.fulfill()
            }
        }

        // when
        try! realTime.reportEvent(event: event)
        waitForExpectations(timeout: realtimeTimeout)
    }

    /// When a SetUserEmail event is reported and there is an internet connection,
    /// the storage value for the realtimeLastSuccessfulSentEmail should be a correct at the end of the flow.
    func test_SetUserEmail_reported_with_internet_expect_correct_lastSuccessfulSentEmail() {
        // given
        prefilledVisitorStorage()

        // and
        let email = StubVariables.userEmail
        storage.userEmail = email

        // and
        let event = SetUserEmailEvent(email: email)

        // then
        let lastSuccessfulSentEmailExpectation = expectation(description: "Last successful email was not generated")
        storage.assertFunction = { (value, key) in
            if key == StorageKey.realtimeLastSuccessfulSentEmail {
                XCTAssertEqual(value as? String, email)
                lastSuccessfulSentEmailExpectation.fulfill()
            }
        }

        // when
        try! realTime.reportEvent(event: event)
        waitForExpectations(timeout: realtimeTimeout)
    }

    /// When a SetUserEmail event is reported and there is no internet connection,
    /// the storage value for the realtimeLastSuccessfulSentEmail should be wrong at the end of the flow.
    func test_SetUserEmail_reported_without_internet_expect_wrong_lastSuccessfulSentEmail() {
        // given
        prefilledVisitorStorage()

        // and
        let email = StubVariables.userEmail
        storage.userEmail = email

        // and
        networking.assertFunction = { event in
            return .failure(NetworkError.requestFailed)
        }

        let event = SetUserEmailEvent(email: storage[.userEmail]!)

        // then
        let lastSuccessfulSentEmailExpectation = expectation(description: "Last successful email was generated")
        lastSuccessfulSentEmailExpectation.isInverted.toggle()
        storage.assertFunction = { (value, key) in
            if key == StorageKey.realtimeLastSuccessfulSentEmail {
                lastSuccessfulSentEmailExpectation.fulfill()
            }
        }

        // when
        try! realTime.reportEvent(event: event)
        waitForExpectations(timeout: realtimeTimeout)
    }

    func test_report_screen_event() {
        // given
        prefilledVisitorStorage()

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
        try! realTime.handle(
            OperationContext(
                .eventable(
                    .reportScreenEvent(customURL: customURL, pageTitle: pageTitle, category: category)
                )
            )
        )
        waitForExpectations(timeout: realtimeTimeout)
    }

    func test_report_without_customerID_and_visitorID() {
        // then
        let eventExpectation = expectation(description: "An error wasn't generated without cid and vid.")
        handler.handleOnErrorAssertFunc = { (eventType: RealTimeEventType, error: Error) in
            XCTAssert(eventType == .regular)
            XCTAssert(error.localizedDescription == RealTimeError.eitherCustomerOrVisitorIdIsNil.localizedDescription)
            eventExpectation.fulfill()
        }
        // when
        try! realTime.reportEvent(event: StubEvent())
        waitForExpectations(timeout: realtimeTimeout)
    }
}

extension StubEvent {

    func isStubEvent(_ event: RealtimeEvent) -> Bool {
        return (event.context[Constnats.key] as? String) == Constnats.value
    }

}
