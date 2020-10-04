//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

final class OnStartEventGeneratorTests: OptimoveTestCase {

    var generator: OnStartEventGenerator!
    var dataProvider: MockDateTimeProvider!
    var synchronizer: MockSynchronizer!

    override func setUp() {
        dataProvider = MockDateTimeProvider()
        synchronizer = MockSynchronizer()
        generator = OnStartEventGenerator(
            coreEventFactory: CoreEventFactoryImpl(
                storage: storage,
                dateTimeProvider: dataProvider,
                locationService: MockLocationService()
            ),
            synchronizer: synchronizer,
            storage: storage
        )
    }

    func test_event_generation() {
        // given
        prefillStorageWithTheFirstLaunch()
        storage.tenantToken = "tenantToken"
        storage.version = "configName"
        storage.configurationEndPoint = URL(string: "http://optimove.net")

        // then
        let metaDataEventExpectation = expectation(description: "MetaDataEvent was not generated.")
        let userAgentEventExpectation = expectation(description: "SetUserAgent was not generated.")
        let appOpenEventExpectation = expectation(description: "AppOpenEvent was not generated.")
        synchronizer.assertFunction = { operation in
            switch operation {
            case let .report(events: events):
                events.forEach { event in
                    switch event.name {
                    case MetaDataEvent.Constants.name:
                        metaDataEventExpectation.fulfill()
                    case SetUserAgent.Constants.name:
                        userAgentEventExpectation.fulfill()
                    case AppOpenEvent.Constants.name:
                        appOpenEventExpectation.fulfill()
                    default:
                        break
                    }
                }
            default:
                break
            }
        }

        // when
        generator.generate()

        wait(
            for: [
                metaDataEventExpectation,
                userAgentEventExpectation,
                appOpenEventExpectation
            ],
            // Additional second to complete the async operation and prevent a flickering.
            timeout: defaultTimeout + 3
        )
    }

}
