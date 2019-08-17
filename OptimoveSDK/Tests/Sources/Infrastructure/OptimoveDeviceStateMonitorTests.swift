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

    func testThatGetStatusesImplWorks() {
        // given
        let requirements: [OptimoveDeviceRequirement] = [
            .advertisingId,
            .internet,
            .userNotification
        ]
        
        // when
        let statusesExpectation = expectation(description: "statuses")
        deviceStateMonitor.getStatuses(for: requirements) { (results) in
            results.forEach({ (result) in
                // then
                XCTAssert(result.value)
            })
            statusesExpectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    // ELI: DeviceStateMonitor in current implementation should execute getStatuses/getStatus
    // at least once for cache statuses.
    // FIXME: Dont use cached values.
//    func test_missing_parameters() {
//        // given
//        let requirements = OptimoveDeviceRequirement.allCases
//        let disabledRequirments: [OptimoveDeviceRequirement] = OptimoveDeviceRequirement.userDependentPermissions
//        let enabledRequirments: [OptimoveDeviceRequirement] = Array(Set(requirements).subtracting(disabledRequirments))
//
//        // and
//        fetchers = {
//            return disabledRequirments.map { MockDeviceRequirementFetcher(type: $0, isEnabled: false) } +
//            enabledRequirments.map { MockDeviceRequirementFetcher(type: $0, isEnabled: true) }
//        }
//
//        // when
//        let missingPermissions = deviceStateMonitor.getMissingPermissions()
//
//        // then
//        XCTAssert(disabledRequirments == missingPermissions,
//                  "Expected \(disabledRequirments). Actual \(missingPermissions)")
//    }

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
