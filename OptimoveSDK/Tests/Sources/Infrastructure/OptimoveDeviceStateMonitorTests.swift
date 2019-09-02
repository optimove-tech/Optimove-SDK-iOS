//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

typealias FetchersGenerator = (() -> [MockDeviceRequirementFetcher])

class OptimoveDeviceStateMonitorTests: XCTestCase {

    var fetchers: FetchersGenerator = {
        return [
            MockDeviceRequirementFetcher(type: .internet, isEnabled: true),
            MockDeviceRequirementFetcher(type: .advertisingId, isEnabled: true),
            MockDeviceRequirementFetcher(type: .userNotification, isEnabled: true)
        ]
    }
    var fetcherFactory: MockDeviceRequirementFetcherFactory!
    var deviceStateMonitor: OptimoveDeviceStateMonitor!

    override func setUp() {
        fetcherFactory = MockDeviceRequirementFetcherFactory(
            fetchers: fetchers
        )
        deviceStateMonitor = OptimoveDeviceStateMonitorImpl(
            fetcherFactory: fetcherFactory
        )
    }

    func testThatGetStatusImplWorks() {
        // given
        let requirements: [OptimoveDeviceRequirement] = [
            .advertisingId,
            .internet,
            .userNotification
        ]

        // when
        var expectations: [XCTestExpectation] = []
        requirements.forEach { requirement in
            let deviceRequirementExpectation = expectation(description: "DeviceRequirement\(requirement.rawValue) was not generated.")
            expectations.append(deviceRequirementExpectation)
            deviceStateMonitor.getStatus(for: requirement, completion: { (status) in
                // then
                XCTAssert(status, "Expect that status is `true`. Actual is \(status)")
                deviceRequirementExpectation.fulfill()
            })
        }
        wait(for: expectations, timeout: 1)
    }

}

class MockDeviceRequirementFetcherFactory: DeviceRequirementFetcherFactory {

    var fetchers: FetchersGenerator

    init(fetchers: @escaping FetchersGenerator) {
        self.fetchers = fetchers
    }

    func createFetcher(for requirement: OptimoveDeviceRequirement) -> Fetchable {
        return fetchers().filter { $0.type == requirement }.first!
    }

}

struct MockDeviceRequirementFetcher: Fetchable {

    let type: OptimoveDeviceRequirement
    var isEnabled: Bool = true

    func fetch(completion: @escaping ResultBlockWithBool) {
        completion(isEnabled)
    }

}
