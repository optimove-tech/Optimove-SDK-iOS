//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

final class OptInOutObserverTests: OptimoveTestCase {

    var observer: OptInOutObserver!
    var synchronizer: MockSynchronizer!
    var notificationPermissionFetcher: MockNotificationPermissionFetcher!

    override func setUp() {
        synchronizer = MockSynchronizer()
        storage = MockOptimoveStorage()
        notificationPermissionFetcher = MockNotificationPermissionFetcher()
        let optInService = OptInService(
            synchronizer: synchronizer,
            coreEventFactory: CoreEventFactoryImpl(
                storage: storage,
                dateTimeProvider: MockDateTimeProvider()
            ),
            storage: storage
        )
        observer = OptInOutObserver(
            optInService: optInService,
            notificationPermissionFetcher: notificationPermissionFetcher
        )
    }

    func test_optFlag_process_for_the_first_time() {
        // given
        prefillPushToken()
        notificationPermissionFetcher.permitted = true

        let optInEventExpectation = expectation(description: "optFlag event was not generated.")
        synchronizer.assertFunctionEventable = { operation in
            switch operation {
            case let .report(event: event):
                switch event.name {
                case OptipushOptInEvent.Constants.optInName:
                    optInEventExpectation.fulfill()
                default:
                    break
                }
            default:
                break
            }
        }

        let optFlagStorageValueExpectation = expectation(description: "optFlag storage value change was not generated.")
        storage.assertFunction = { (value, key) in
            if key == .optFlag {
                optFlagStorageValueExpectation.fulfill()
            }
        }

        // when
        observer.observe()

        // then
        wait(
            for: [
                optInEventExpectation,
                optFlagStorageValueExpectation,
            ],
            timeout: defaultTimeout
        )
    }

    func test_optFlag_after_disallow_notifications() {
        // given
        storage.optFlag = true
        notificationPermissionFetcher.permitted = false

        let optFlagEventExpectation = expectation(description: "OptOut event was not generated.")
        synchronizer.assertFunctionEventable = { operation in
            switch operation {
            case let .report(event: event):
                switch event.name {
                case OptipushOptInEvent.Constants.optOutName:
                    optFlagEventExpectation.fulfill()
                default:
                    break
                }
            default:
                break
            }
        }

        let optFlagStorageValueExpectation = expectation(description: "OptIn storage value change was not generated.")
        storage.assertFunction = { (value, key) in
            if key == .optFlag {
                XCTAssertEqual(value as? Bool, false)
                optFlagStorageValueExpectation.fulfill()
            }
        }

        let optFlagOperationExpectation = expectation(description: "OptOut operation was not generated.")
        synchronizer.assertFunctionPushable = { operation in
            switch operation {
            case .optOut:
                optFlagOperationExpectation.fulfill()
            default:
                break
            }
        }

        // when
        observer.observe()

        // then
        wait(
            for: [
                optFlagEventExpectation,
                optFlagStorageValueExpectation,
                optFlagOperationExpectation
            ],
            timeout: defaultTimeout
        )
    }

    func test_optFlag_after_allow_notifications() {
        // given
        storage.optFlag = false
        notificationPermissionFetcher.permitted = true

        let optFlagEventExpectation = expectation(description: "OptOut event was not generated.")
        synchronizer.assertFunctionEventable = { operation in
            switch operation {
            case let .report(event: event):
                switch event.name {
                case OptipushOptInEvent.Constants.optInName:
                    optFlagEventExpectation.fulfill()
                default:
                    break
                }
            default:
                break
            }
        }

        let optFlagStorageValueExpectation = expectation(description: "OptIn storage value change was not generated.")
        storage.assertFunction = { (value, key) in
            if key == .optFlag {
                XCTAssertEqual(value as? Bool, true)
                optFlagStorageValueExpectation.fulfill()
            }
        }

        let optFlagOperationExpectation = expectation(description: "OptOut operation was not generated.")
        synchronizer.assertFunctionPushable = { operation in
            switch operation {
            case .optIn:
                optFlagOperationExpectation.fulfill()
            default:
                break
            }
        }

        // when
        observer.observe()

        // then
        wait(
            for: [
                optFlagEventExpectation,
                optFlagStorageValueExpectation,
                optFlagOperationExpectation
            ],
            timeout: defaultTimeout
        )
    }

}
