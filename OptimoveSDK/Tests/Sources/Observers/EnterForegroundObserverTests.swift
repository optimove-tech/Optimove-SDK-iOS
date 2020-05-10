//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

class EnterForegroundObserverTests: XCTestCase {

    var observer: AppOpenObserver!
    var storage = MockOptimoveStorage()
    var dateProvider = MockDateTimeProvider()
    var statisticService = MockStatisticService()
    var synchronizer = MockSynchronizer()

    override func setUp() {
        observer = AppOpenObserver(
            synchronizer: synchronizer,
            statisticService: statisticService,
            dateTimeProvider: dateProvider,
            coreEventFactory: CoreEventFactoryImpl(
                storage: storage,
                dateTimeProvider: dateProvider,
                locationService: MockLocationService()
            )
        )
    }

// Disabled test for GitHub Actions. There should apply refactoring to prevent using UIKit.
//    func test_app_open_threshold_should_invoke() {
//        // given
//        /// Set the Last open time as Throttling time plus 10 sec.
//        let throttlingTimeGap = AppOpenObserver.Constants.AppOpen.throttlingThreshold + 10
//        statisticService.applicationOpenTime = Date().addingTimeInterval(-throttlingTimeGap).timeIntervalSince1970
//
//        // and
//        observer.observe()
//
//        // then
//        let appOpenEventExpectation = expectation(description: "AppOpenEvent was not generated.")
//        synchronizer.assertFunctionEventable = { operation in
//            switch operation {
//            case let .report(event: event):
//                if event.name == AppOpenEvent.Constants.name {
//                    appOpenEventExpectation.fulfill()
//                }
//            default:
//                break
//            }
//        }
//
//        let applicationOpenTimeExpectation = KVOExpectation(object: statisticService, keyPath: \.applicationOpenTime)
//
//        // when
//        DispatchQueue.main.async {
//            NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
//        }
//
//        wait(for: [appOpenEventExpectation, applicationOpenTimeExpectation], timeout: defaultTimeout)
//    }

    func test_app_open_threshold_should_not_invoke() {
        // given
        /// Set the Last open time as Throttling time minus 10 sec.
        let throttlingTimeGap = AppOpenObserver.Constants.AppOpen.throttlingThreshold - 10
        statisticService.applicationOpenTime = Date().addingTimeInterval(-throttlingTimeGap).timeIntervalSince1970

        // and
        observer.observe()

        // then
        let appOpenEventExpectation = expectation(description: "AppOpenEvent was not generated.")
        appOpenEventExpectation.isInverted.toggle()
        synchronizer.assertFunction = { operation in
            switch operation {
            case let .report(events: events):
                events.forEach { event in
                    if event.name == AppOpenEvent.Constants.name {
                        appOpenEventExpectation.fulfill()
                    }
                }
            default:
                break
            }
        }

        let applicationOpenTimeExpectation = KVOExpectation(object: statisticService, keyPath: \.applicationOpenTime)
        applicationOpenTimeExpectation.isInverted.toggle()

        // when
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        wait(for: [appOpenEventExpectation, applicationOpenTimeExpectation], timeout: defaultTimeout)
    }

}
