//  Copyright © 2019 Optimove. All rights reserved.

@testable import OptimoveSDK
import XCTest

class MergeRemoteConfigurationOperationTests: XCTestCase {
    var repository = MockConfigurationRepository()
    var merger: MergeRemoteConfigurationOperation!

    override func setUp() {
        merger = MergeRemoteConfigurationOperation(
            repository: repository
        )
    }

    func test_merge_config() {
        let globalConfig = GlobalConfigFixture().build()
        try! repository.saveGlobal(globalConfig)

        let tenantConfig = TenantConfigFixture().build()
        try! repository.saveTenant(tenantConfig)

        OperationQueue().addOperations([merger], waitUntilFinished: true)

        XCTAssertEqual(repository.global, GlobalConfigFixture().build())
    }

    func test_merge_config_without_tenant_and_global_configs() {
        OperationQueue().addOperations([merger], waitUntilFinished: true)
        XCTAssertNil(repository.global)
    }
}
