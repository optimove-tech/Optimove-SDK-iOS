//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import OptimoveCore
@testable import OptimoveSDK
import Mocker

class GlobalConfigurationDownloaderTests: XCTestCase {

    var repository = MockConfigurationRepository()
    var downloader: GlobalConfigurationDownloader!

    override func setUp() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockingURLProtocol.self]
        downloader = GlobalConfigurationDownloader(
            networking: RemoteConfigurationNetworking(
                networkClient: NetworkClientImpl(configuration: configuration),
                requestBuilder: RemoteConfigurationRequestBuilder(
                    storage: MockOptimoveStorage()
                )
            ),
            repository: repository
        )
    }

    func test_fetch_global_config() {
        let expectedConfig = GlobalConfigFixture().build()
        Mocker.register(
            Mock(
                url: Endpoints.Remote.GlobalConfig.url(SDK.environment),
                contentType: .json,
                statusCode: 200,
                data: [.get: try! JSONEncoder().encode(expectedConfig)]
            )
        )

        OperationQueue().addOperations([downloader], waitUntilFinished: true)

        XCTAssertEqual(repository.global, expectedConfig)
    }

}
