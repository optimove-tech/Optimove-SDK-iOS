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

    func test_optIn_process_for_the_first_time() {
        // given
        storage.isOptiTrackOptIn = false
        notificationPermissionFetcher.permitted = true

        let optInEventExpectation = expectation(description: "OptIn event was not generated.")
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

        let optInStorageValueExpectation = expectation(description: "OptIn storage value change was not generated.")
        let mbaasOptInStorageValueExpectation = expectation(description: "MBAAS optIn value change was not generated.")
        storage.assertFunction = { (value, key) in
            if key == .isOptiTrackOptIn {
                XCTAssertEqual(value as? Bool, true)
                optInStorageValueExpectation.fulfill()
            }
            if key == .isMbaasOptIn {
                XCTAssertEqual(value as? Bool, true)
                mbaasOptInStorageValueExpectation.fulfill()
            }
        }

        // when
        observer.observe()

        // then
        wait(
            for: [
                optInEventExpectation,
                optInStorageValueExpectation,
                mbaasOptInStorageValueExpectation
            ],
            timeout: defaultTimeout
        )
    }

    func test_no_optInOut_changes() {
        // given
        storage.isOptiTrackOptIn = true
        notificationPermissionFetcher.permitted = true

        let pushableOperationExpectation = expectation(description: "Pushable  operation was generated.")
        pushableOperationExpectation.isInverted.toggle()
        synchronizer.assertFunctionPushable = { operation in
            pushableOperationExpectation.fulfill()
        }

        // when
        observer.observe()

        // then
        wait(for: [pushableOperationExpectation], timeout: defaultTimeout)
    }

    func test_optOut_after_disallow_notifications_for_the_first_time() {
        // given
        storage.isOptiTrackOptIn = true
        notificationPermissionFetcher.permitted = false
        storage.fcmToken = StubVariables.string

        let optOutEventExpectation = expectation(description: "OptOut event was not generated.")
        synchronizer.assertFunctionEventable = { operation in
            switch operation {
            case let .report(event: event):
                switch event.name {
                case OptipushOptInEvent.Constants.optOutName:
                    optOutEventExpectation.fulfill()
                default:
                    break
                }
            default:
                break
            }
        }

        let optInStorageValueExpectation = expectation(description: "OptIn storage value change was not generated.")
        let mbaasOptInStorageValueExpectation = expectation(description: "MBAAS optIn value change was not generated.")
        storage.assertFunction = { (value, key) in
            if key == .isOptiTrackOptIn {
                XCTAssertEqual(value as? Bool, false)
                optInStorageValueExpectation.fulfill()
            }
            if key == .isMbaasOptIn {
                XCTAssertEqual(value as? Bool, false)
                mbaasOptInStorageValueExpectation.fulfill()
            }
        }

        let optOutOperationExpectation = expectation(description: "OptOut operation was not generated.")
        synchronizer.assertFunctionPushable = { operation in
            switch operation {
            case .optOut:
                optOutOperationExpectation.fulfill()
            default:
                break
            }
        }

        // when
        observer.observe()

        // then
        wait(
            for: [
                optOutEventExpectation,
                optInStorageValueExpectation,
                optOutOperationExpectation,
                mbaasOptInStorageValueExpectation
            ],
            timeout: defaultTimeout
        )
    }

    func test_optOut_after_disallow_notifications() {
        // given
        storage.isOptiTrackOptIn = true
        storage.isMbaasOptIn = true
        notificationPermissionFetcher.permitted = false
        storage.fcmToken = StubVariables.string

        let optOutEventExpectation = expectation(description: "OptOut event was not generated.")
        synchronizer.assertFunctionEventable = { operation in
            switch operation {
            case let .report(event: event):
                switch event.name {
                case OptipushOptInEvent.Constants.optOutName:
                    optOutEventExpectation.fulfill()
                default:
                    break
                }
            default:
                break
            }
        }

        let optInStorageValueExpectation = expectation(description: "OptIn storage value change was not generated.")
        let mbaasOptInStorageValueExpectation = expectation(description: "MBAAS optIn value change was not generated.")
        storage.assertFunction = { (value, key) in
            if key == .isOptiTrackOptIn {
                XCTAssertEqual(value as? Bool, false)
                optInStorageValueExpectation.fulfill()
            }
            if key == .isMbaasOptIn {
                XCTAssertEqual(value as? Bool, false)
                mbaasOptInStorageValueExpectation.fulfill()
            }
        }

        let optOutOperationExpectation = expectation(description: "OptOut operation was not generated.")
        synchronizer.assertFunctionPushable = { operation in
            switch operation {
            case .optOut:
                optOutOperationExpectation.fulfill()
            default:
                break
            }
        }

        // when
        observer.observe()

        // then
        wait(
            for: [
                optOutEventExpectation,
                optInStorageValueExpectation,
                optOutOperationExpectation,
                mbaasOptInStorageValueExpectation
            ],
            timeout: defaultTimeout
        )
    }

}
