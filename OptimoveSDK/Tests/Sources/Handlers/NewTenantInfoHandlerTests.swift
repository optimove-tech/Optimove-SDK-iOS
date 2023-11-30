//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore
@testable import OptimoveSDK
import XCTest

class NewTenantInfoHandlerTests: XCTestCase {
    var storage = MockOptimoveStorage()

    func test_tenant_info_save_correctly() {
        let tenantToken = "tenantToken"
        let configName = "configName"
        let tenantInfo = OptimoveTenantInfo(tenantToken: tenantToken, configName: configName)

        let handler = NewTenantInfoHandler(storage: storage)

        storage.assertFunction = { value, key in
            if key == .tenantToken {
                XCTAssertEqual(value as? String, tenantToken)
            }
            if key == .version {
                XCTAssertEqual(value as? String, configName)
            }
            if key == .configurationEndPoint {
                XCTAssertEqual(value as? String, Endpoints.Remote.TenantConfig.url.absoluteString)
            }
        }

        handler.handle(tenantInfo)
    }
}
