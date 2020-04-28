//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import OptimoveCore
@testable import OptimoveSDK

final class OptiTrackComponentTests: OptimoveTestCase {

    var optitrack: OptiTrack!
    var dateProvider = MockDateTimeProvider()
    var statisticService = MockStatisticService()
    var networking = OptistreamNetworkingMock()
    var queue = MockOptistreamQueue()
    var builder: OptistreamEventBuilder!

    override func setUp() {
        let configuration = ConfigurationFixture.build()
        builder = OptistreamEventBuilder(
            configuration: configuration.optitrack,
            storage: storage,
            airshipService: AirshipService(
                storage: storage,
                configuration: configuration
            )
        )
        optitrack = OptiTrack(
            queue: queue,
            optirstreamEventBuilder: builder,
            networking: networking
        )
        optitrack.dispatchInterval = 1
    }

    func test_event_one_report() throws {
        // given
        prefillStorageAsVisitor()
        let stubEvent = StubEvent()

        // then
        let networkExpectation = expectation(description: "track event haven't been generated.")
        networking.assetManyEventsFunction = { (events, completion) -> Void in
            XCTAssertEqual(events.count, 1)
            networkExpectation.fulfill()
        }

        // when
        try optitrack.handle(.report(event: stubEvent))
        wait(for: [networkExpectation], timeout: defaultTimeout + 5)
    }

    func test_event_many_reports() throws {
        // given
        prefillStorageAsVisitor()
        let stubEvents = [StubEvent(), StubEvent()]
        queue.events = stubEvents.map({ try! self.builder.build(event: $0) })

        // then
        let networkExpectation = expectation(description: "track event haven't been generated.")
        networking.assetManyEventsFunction = { (events, completion) -> Void in
            XCTAssertEqual(stubEvents.count, events.count)
            networkExpectation.fulfill()
        }

        // when
        try optitrack.handle(.dispatchNow)
        wait(for: [networkExpectation], timeout: defaultTimeout + 1)
    }

}

final class MockOptistreamQueue: OptistreamQueue {

    var events: [OptistreamEvent] = []

    var eventCount: Int {
        return events.count
    }

    func enqueue(events: [OptistreamEvent]) {
        self.events.append(contentsOf: events)
    }

    func first(limit: Int) -> [OptistreamEvent] {
        let amount = limit <= eventCount ? limit : eventCount
        return Array(self.events[0..<amount])
    }

    func remove(events: [OptistreamEvent]) {
        self.events = self.events.filter { cachedEvent in
            !events.contains(cachedEvent) // O(n*n)
        }
    }

}
