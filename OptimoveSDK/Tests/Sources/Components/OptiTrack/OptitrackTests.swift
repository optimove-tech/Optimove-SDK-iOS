//  Copyright © 2020 Optimove. All rights reserved.


import XCTest
import OptimoveCore
@testable import OptimoveSDK

class OptitrackTests: OptimoveTestCase {

    var optitrack: OptiTrack!
    var networking: OptistreamNetworkingMock!
    var builder: OptistreamEventBuilder!
    let dispatchInterval: TimeInterval = 1

    override func setUpWithError() throws {
        let configuration = ConfigurationFixture.build(
            Options(isEnableRealtime: true, isEnableRealtimeThroughOptistream: true)
        )
        networking = OptistreamNetworkingMock()
        let queue = try OptistreamQueueImpl(
            queueType: .track,
            container: PersistentContainer(),
            tenant: configuration.tenantID
        )
        builder = OptistreamEventBuilder(
            tenantID: configuration.optitrack.tenantID,
            storage: storage,
            airshipIntegration: OptimoveAirshipIntegration(
                storage: storage,
                isSupportedAirship: configuration.isSupportedAirship
            )
        )
        optitrack = OptiTrack(
            queue: queue,
            networking: networking,
            configuration: configuration.optitrack
        )
        optitrack?.dispatchInterval = dispatchInterval
    }

    override func tearDownWithError() throws {
        self.optitrack = nil
        self.networking = nil
        self.builder = nil
    }
    
    func disabled_test_load_realtime() throws {
        prefillStorageAsCustomer()
        let events: [Event] = Array(repeating: 1, count: 102).map { _ in
            let event = StubEvent()
            event.isRealtime = true
            return event
        }
        try test(events)
    }

    func disabled_test_load() throws {
        prefillStorageAsCustomer()
        let events = Array(repeating: 1, count: 90).map { _ in StubEvent() }
        try test(events)
    }

    func test(_ incomingEvents: [Event]) throws {
        let events = incomingEvents.map { try! self.builder.build(event: $0) }
        let eventsCountExpectation = expectation(description:
            "do not reach \(events.count) realtime event while processing"
        )
        eventsCountExpectation.expectedFulfillmentCount = events.count
        eventsCountExpectation.assertForOverFulfill = false
        let batchTimes = Int((Double(events.count) / Double(OptiTrack.Constants.eventBatchLimit)).rounded(.up))
        let batchExpectation = expectation(description:
            "do not generate right amount of batches \(batchTimes)"
        )
        batchExpectation.expectedFulfillmentCount = batchTimes
        var eventIds: [String] = [];
        networking.assetEventsFunction = { (events, completion) -> Void in
            events.enumerated().forEach { event in
                let eventId = event.element.metadata.eventId
                if eventIds.contains(eventId) {
                    XCTFail("Event with id \(eventId) is duplicated")
                }
                eventIds.append(eventId)
                eventsCountExpectation.fulfill()
            }
            batchExpectation.fulfill()
            completion(.success(()))
        }

        try optitrack?.handle(.report(events: events))
        waitForExpectations(timeout: 10, handler: { (error) -> Void in
            print("Number of procceded events \(eventIds.count), with error: \(error.debugDescription)")
        })
    }

}
