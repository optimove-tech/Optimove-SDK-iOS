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

}
