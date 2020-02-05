//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import Mocker
@testable import OptimoveSDK

class RegistrarNetworkingTests: OptimoveTestCase {

    var networking: ApiNetworking!
    let config = ConfigurationFixture.build().optipush

    override func setUp() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockingURLProtocol.self]
        let client = NetworkClientImpl(configuration: configuration)
        let payloadBuilder = ApiPayloadBuilder(
            storage: storage,
            appNamespace: try! Bundle.getApplicationNameSpace()
        )
        let requestFactory = ApiRequestFactory(
            storage: storage,
            payloadBuilder: payloadBuilder,
            requestBuilder: ApiRequestBuilder(
                optipushConfig: config
            )
        )
        networking = ApiNetworkingImpl(
            networkClient: client,
            requestFactory: requestFactory
        )
    }

    func test_addOrUpdateUser() {
        // given
        prefillStorageAsVisitor()
        prefillPushToken()

        Mocker.register(
            Mock(
                url: config.mbaasEndpoint
                    .appendingPathComponent(ApiRequestBuilder.Constants.tenantsPath)
                    .appendingPathComponent(String(config.tenantID))
                    .appendingPathComponent(ApiRequestBuilder.Constants.installationPath),
                dataType: .json,
                statusCode: 200,
                data: [.post: Data()]
            )
        )

        // when
        let resultExpectation = expectation(description: "Result was not generated.")
        networking.sendToMbaas(operation: .setInstallation) { (result) in
            switch result {
            case .success:
                resultExpectation.fulfill()
            case .failure:
                XCTFail()
            }
        }

        // then
        wait(for: [resultExpectation], timeout: defaultTimeout)
    }

    func test_migrate_user() {
        // given
        prefillStorageAsCustomer()
        prefillPushToken()

        Mocker.register(
            Mock(
                url: config.mbaasEndpoint
                    .appendingPathComponent(ApiRequestBuilder.Constants.tenantsPath)
                    .appendingPathComponent(String(config.tenantID))
                    .appendingPathComponent(ApiRequestBuilder.Constants.installationPath),
                dataType: .json,
                statusCode: 200,
                data: [.post: Data()]
            )
        )

        // when
        let resultExpectation = expectation(description: "Result was not generated.")
        networking.sendToMbaas(operation: .setInstallation) { (result) in
            switch result {
            case .success:
                resultExpectation.fulfill()
            case .failure:
                XCTFail()
            }
        }

        // then
        wait(for: [resultExpectation], timeout: defaultTimeout)
    }

}
