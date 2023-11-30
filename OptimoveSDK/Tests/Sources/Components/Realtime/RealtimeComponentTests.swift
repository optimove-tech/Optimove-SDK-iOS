//  Copyright © 2020 Optimove. All rights reserved.

import OptimoveCore
@testable import OptimoveSDK
import XCTest

class RealtimeComponentTests: OptimoveTestCase {
    var realtime: RealTime!
    var networking = OptistreamNetworkingMock()
    var queue = MockOptistreamQueue()

    func test_RT_events_order() throws {
        let configuration = ConfigurationFixture.build()
        realtime = RealTime(
            configuration: configuration.realtime,
            storage: storage,
            networking: networking,
            queue: queue
        )

        let event1 = FixtureOptistreamEvent.generateEvent(event: "event1")
        let event2 = FixtureOptistreamEvent.generateEvent(event: "event2")
        let event1Expectation = expectation(description: "\(event1.event) was not generated")
        let event2Expectation = expectation(description: "\(event2.event) was not generated")
        networking.assetEventsFunction = { events, _ in
            events.forEach { event in
                switch event.event {
                case event1.event:
                    event1Expectation.fulfill()
                case event2.event:
                    event2Expectation.fulfill()
                default:
                    break
                }
            }
        }
        try realtime.serve(.report(events: [event1, event2]))
        wait(
            for: [event1Expectation, event2Expectation],
            timeout: defaultTimeout,
            enforceOrder: true
        )
    }

    func test_RT_does_not_send_events_if_isEnableRealtimeThroughOptistream() throws {
        let configuration = ConfigurationFixture.build(
            Options(
                isEnableRealtime: true,
                isEnableRealtimeThroughOptistream: true
            )
        )
        realtime = RealTime(
            configuration: configuration.realtime,
            storage: storage,
            networking: networking,
            queue: queue
        )
        let event1 = FixtureOptistreamEvent.generateEvent(event: "event1")
        let event1Expectation = expectation(description: "\(event1.event) was not generated")
        event1Expectation.isInverted.toggle()
        networking.assetEventsFunction = { events, _ in
            events.forEach { event in
                switch event.event {
                case event1.event:
                    event1Expectation.fulfill()
                default:
                    break
                }
            }
        }
        try realtime.serve(.report(events: [event1]))
        wait(
            for: [event1Expectation],
            timeout: defaultTimeout
        )
    }
}

enum FixtureOptistreamEvent {
    static func generateEvent(event: String) -> OptistreamEvent {
        return OptistreamEvent(
            tenant: StubVariables.tenantID,
            category: "test",
            event: event,
            origin: "sdk",
            customer: nil,
            visitor: StubVariables.visitorID,
            timestamp: Formatter.iso8601withFractionalSeconds.string(from: Date()),
            context: [],
            metadata: OptistreamEvent.Metadata(
                realtime: true,
                firstVisitorDate: Date().timeIntervalSince1970.seconds,
                eventId: UUID().uuidString,
                requestId: UUID().uuidString
            )
        )
    }
}
