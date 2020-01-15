//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import Mocker
@testable import OptimoveSDK

class RegistrarNetworkingTests: OptimoveTestCase {

    var networking: RegistrarNetworking!
    let config = ConfigurationFixture.build().optipush

    override func setUp() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockingURLProtocol.self]
        let client = NetworkClientImpl(configuration: configuration)
        let payloadBuilder = ApiPayloadBuilder(
            storage: storage,
            deviceID: SDKDevice.uuid,
            appNamespace: try! Bundle.getApplicationNameSpace()
        )
        let requestFactory = RegistrarNetworkingRequestFactory(
            storage: storage,
            payloadBuilder: payloadBuilder,
            requestBuilder: ClientAPIRequestBuilder(
                optipushConfig: config
            )
        )
        networking = RegistrarNetworkingImpl(
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
                    .appendingPathComponent(ClientAPIRequestBuilder.Constants.tenantsPath)
                    .appendingPathComponent(String(config.tenantID))
                    .appendingPathComponent(ClientAPIRequestBuilder.Constants.usersPath)
                    .appendingPathComponent(storage.initialVisitorId!),
                dataType: .json,
                statusCode: 200,
                data: [.post: Data()]
            )
        )

        // when
        let resultExpectation = expectation(description: "Result was not generated.")
        networking.sendToMbaas(operation: .setUser) { (result) in
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

        Mocker.register(
            Mock(
                url: config.mbaasEndpoint
                    .appendingPathComponent(ClientAPIRequestBuilder.Constants.tenantsPath)
                    .appendingPathComponent(String(config.tenantID))
                    .appendingPathComponent(ClientAPIRequestBuilder.Constants.usersPath)
                    .appendingPathComponent(storage.initialVisitorId!),
                dataType: .json,
                statusCode: 200,
                data: [.put: Data()]
            )
        )

        // when
        let resultExpectation = expectation(description: "Result was not generated.")
        networking.sendToMbaas(operation: .addUserAlias) { (result) in
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
