//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import OptimoveCore
@testable import OptimoveSDK
import Mocker

class TenantConfigurationDownloaderTests: XCTestCase {

    var repository = MockConfigurationRepository()
    var downloader: TenantConfigurationDownloader!
    var storage = MockOptimoveStorage()

    override func setUp() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockingURLProtocol.self]
        storage = MockOptimoveStorage()
        downloader = TenantConfigurationDownloader(
            networking: RemoteConfigurationNetworking(
                networkClient: NetworkClientImpl(configuration: configuration),
                requestBuilder: RemoteConfigurationRequestBuilder(
                    storage: storage
                )
            ),
            repository: repository
        )
    }

    func test_fetch_global_config() throws {
        let tenantToken = String.randomString(length: 10)
        storage.tenantToken = tenantToken
        let version = String.randomString(length: 10)
        storage.version = version

        let expectedURL = Endpoints.Remote.TenantConfig.url
            .appendingPathComponent(tenantToken)
            .appendingPathComponent(version)
            .appendingPathExtension("json")

        let expectedConfig = TenantConfigFixture().build()
        Mocker.register(
            Mock(
                url: expectedURL,
                dataType: .json,
                statusCode: 200,
                data: [.get: try JSONEncoder().encode(expectedConfig)]
            )
        )

        OperationQueue().addOperations([downloader], waitUntilFinished: true)

        XCTAssertEqual(repository.tenant, expectedConfig)
    }

}
