//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore
@testable import OptimoveSDK
import XCTest

final class OptiTrackMockQueueTests: OptimoveTestCase {
    var optitrack: OptiTrack!
    var dateProvider = MockDateTimeProvider()
    var statisticService = MockStatisticService()
    var networking: OptistreamNetworkingMock!
    var queue: MockOptistreamQueue!
    var builder: OptistreamEventBuilder!
    let dispatchInterval: TimeInterval = 1

    override func setUp() {
        networking = OptistreamNetworkingMock()
        queue = MockOptistreamQueue()
        let configuration = ConfigurationFixture.build(
            Options(isEnableRealtime: true, isEnableRealtimeThroughOptistream: true)
        )
        builder = OptistreamEventBuilder(
            tenantID: configuration.optitrack.tenantID,
            storage: storage
        )
        optitrack = OptiTrack(
            queue: queue,
            networking: networking,
            configuration: configuration.optitrack
        )
        optitrack.dispatchInterval = dispatchInterval
    }

    func test_event_one_report() throws {
        // given
        prefillStorageAsVisitor()
        let stubEvent = StubOptistreamEvent

        // then
        let networkExpectation = expectation(description: "track event haven't been generated.")
        networking.assetEventsFunction = { events, _ in
            XCTAssertEqual(events.count, 1)
            networkExpectation.fulfill()
        }

        // when
        try optitrack.serve(.report(events: [stubEvent]))
        wait(for: [networkExpectation], timeout: defaultTimeout + dispatchInterval * 2)
    }

    func test_event_many_reports() throws {
        // given
        prefillStorageAsVisitor()
        let stubEvents = [StubEvent(), StubEvent()]
        queue.events = stubEvents.map { try! self.builder.build(event: $0) }

        // then
        let networkExpectation = expectation(description: "track event haven't been generated.")
        networking.assetEventsFunction = { events, _ in
            XCTAssertEqual(stubEvents.count, events.count)
            networkExpectation.fulfill()
        }

        // when
        try optitrack.serve(.dispatchNow)
        wait(for: [networkExpectation], timeout: defaultTimeout + dispatchInterval)
    }
}
