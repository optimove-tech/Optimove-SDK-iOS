//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

final class OnStartEventGeneratorTests: XCTestCase {

    var generator: OnStartEventGenerator!
    var storage: MockOptimoveStorage!
    var dataProvider: MockDateTimeProvider!
    var synchronizer: MockSynchronizer!

    override func setUp() {
        storage = MockOptimoveStorage()
        dataProvider = MockDateTimeProvider()
        synchronizer = MockSynchronizer()
        generator = OnStartEventGenerator(
            coreEventFactory: CoreEventFactoryImpl(
                storage: storage,
                dateTimeProvider: dataProvider
            ),
            synchronizer: synchronizer,
            storage: storage
        )
    }

    func test_event_generation() {
        // given
        storage.tenantToken = "tenantToken"
        storage.version = "configName"
        storage.configurationEndPoint = URL(string: "http://optimove.net")

        // then
        let ifdaEventExpectation = expectation(description: "SetAdvertisingIdEvent was not generated.")
        let metaDataEventExpectation = expectation(description: "MetaDataEvent was not generated.")
        let userAgentEventExpectation = expectation(description: "SetUserAgent was not generated.")
        let appOpenEventExpectation = expectation(description: "AppOpenEvent was not generated.")
        synchronizer.assertFunctionEventable = { (operation: EventableOperation) -> Void in
            switch operation {
            case let .report(event: event):
                switch event.name {
                case SetAdvertisingIdEvent.Constants.name:
                    ifdaEventExpectation.fulfill()
                case MetaDataEvent.Constants.name:
                    metaDataEventExpectation.fulfill()
                case SetUserAgent.Constants.name:
                    userAgentEventExpectation.fulfill()
                case AppOpenEvent.Constants.name:
                    appOpenEventExpectation.fulfill()
                default:
                    break
                }
            default:
                break
            }
        }

        // when
        generator.generate()
        wait(
            for: [
                ifdaEventExpectation,
                metaDataEventExpectation,
                userAgentEventExpectation,
                appOpenEventExpectation
            ],
            timeout: 5
        )
    }

    //    func test_handleWillEnterForegroundNotification() {
    //        // given
    //        storage.visitorID = StubVariables.visitorID
    //
    //        // and
    //        let now = Date()
    //        let throttlingThreshold = OptiTrack.Constants.AppOpen.throttlingThreshold
    //        let applicationOpenTime = now.addingTimeInterval(-(throttlingThreshold + 1)).timeIntervalSince1970
    //
    //        // when
    //        statisticService.applicationOpenTime = applicationOpenTime
    //        dateProvider.mockedNow = now
    //
    //        // then
    //        let trackEventExpectation = expectation(description: "track event haven't been generate.")
    //        tracker.trackEventAssertFunction = { (event: TrackerEvent) -> Void in
    //            XCTAssert(event.action == AppOpenEvent.Constants.name,
    //                      "Expect \(AppOpenEvent.Constants.name). Actual \(event.action)")
    //            trackEventExpectation.fulfill()
    //        }
    //        XCTAssertNoThrow(try optitrack.handleWillEnterForegroundNotification())
    //        wait(for: [trackEventExpectation], timeout: defaultTimeout, enforceOrder: true)
    //    }

    //    func test_willEnterForegroundNotification_action_throttled() {
    //        // given
    //        storage.visitorID = StubVariables.visitorID
    //
    //        // and
    //        let now = Date()
    //        // Application was opened 10 sec ago.
    //        let applicationOpenTime = now.addingTimeInterval(-(10)).timeIntervalSince1970
    //
    //        // when
    //        statisticService.applicationOpenTime = applicationOpenTime
    //        dateProvider.mockedNow = now
    //
    //        // then
    //        let trackEventExpectation = expectation(description: "track event haven't been generate.")
    //        trackEventExpectation.isInverted = true
    //        tracker.trackEventAssertFunction = { (event: TrackerEvent) -> Void in
    //            XCTAssert(event.action == AppOpenEvent.Constants.name,
    //                      "Expect \(AppOpenEvent.Constants.name). Actual \(event.action)")
    //            trackEventExpectation.fulfill()
    //        }
    //        XCTAssertNoThrow(try optitrack.handleWillEnterForegroundNotification())
    //        wait(for: [trackEventExpectation], timeout: defaultTimeout, enforceOrder: true)
    //    }

    //    func test_reportPendingEvents() {
    //        // then
    //        let trackEventExpectation = expectation(description: "track dispath pending events haven't been generated.")
    //        tracker.dispathPendingEventsAssertFunction = {
    //            trackEventExpectation.fulfill()
    //        }
    //
    //        // when
    //        optitrack.reportPendingEvents()
    //        wait(for: [trackEventExpectation], timeout: defaultTimeout, enforceOrder: true)
    //    }

}
