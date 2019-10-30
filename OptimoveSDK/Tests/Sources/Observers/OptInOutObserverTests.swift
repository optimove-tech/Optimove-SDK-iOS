//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

final class OptInOutObserverTests: XCTestCase {

    var observer: OptInOutObserver!
    var synchronizer: MockSynchronizer!
    var notificationPermissionFetcher: MockNotificationPermissionFetcher!
    var storage: MockOptimoveStorage!

    override func setUp() {
        synchronizer = MockSynchronizer()
        storage = MockOptimoveStorage()
        notificationPermissionFetcher = MockNotificationPermissionFetcher()
        observer = OptInOutObserver(
            synchronizer: synchronizer,
            notificationPermissionFetcher: notificationPermissionFetcher,
            coreEventFactory: CoreEventFactoryImpl(
                storage: storage,
                dateTimeProvider: MockDateTimeProvider()
            ),
            storage: storage
        )
    }

    func test_optFlag_process_for_the_first_time() {
        // given
        // storage.optFlag has default value `true`
        notificationPermissionFetcher.permitted = true

        let optInEventExpectation = expectation(description: "optFlag event was not generated.")
        optInEventExpectation.isInverted.toggle()
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
        optFlagStorageValueExpectation.isInverted.toggle()
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
