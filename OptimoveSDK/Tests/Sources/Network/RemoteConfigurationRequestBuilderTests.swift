//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK
import OptimoveCore

final class RemoteConfigurationRequestBuilderTests: XCTestCase {

    var requestBuilder: RemoteConfigurationRequestBuilder!
    var storage: MockOptimoveStorage!

    override func setUp() {
        storage = MockOptimoveStorage()
        requestBuilder = RemoteConfigurationRequestBuilder(
            storage: storage
        )
    }

    func test_global_config_request() {
        let request = requestBuilder.createGlobalConfigurationsRequest()

        XCTAssertEqual(request.baseURL, Endpoints.Remote.GlobalConfig.url(SDK.environment))
        XCTAssertEqual(request.method, HTTPMethod.get)
    }

    func test_tenant_config_request() {
        let tenantToken = String.randomString(length: 10)
        storage.tenantToken = tenantToken
        let version = String.randomString(length: 10)
        storage.version = version

        let expectedURL = Endpoints.Remote.TenantConfig.url
            .appendingPathComponent(tenantToken)
            .appendingPathComponent(version)
            .appendingPathExtension("json")

        XCTAssertNoThrow(try requestBuilder.createTenantConfigurationsRequest())
        let request = try! requestBuilder.createTenantConfigurationsRequest()

        XCTAssertEqual(request.baseURL, expectedURL)
        XCTAssertEqual(request.method, HTTPMethod.get)
    }
}
