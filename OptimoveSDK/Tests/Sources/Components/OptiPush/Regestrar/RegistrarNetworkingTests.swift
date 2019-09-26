//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import Mocker
@testable import OptimoveSDK

class RegistrarNetworkingTests: OptimoveTestCase {

    var networking: RegistrarNetworking!
    let url = StubVariables.url

    override func setUp() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockingURLProtocol.self]
        let client = NetworkClientImpl(configuration: configuration)
        let payloadBuilder = MbaasPayloadBuilder(
            storage: storage,
            device: SDKDevice.self,
            bundle: Bundle.self
        )
        let requestFactory = RegistrarNetworkingRequestFactory(
            storage: storage,
            configuration: ConfigurationFixture.build().optipush,
            payloadBuilder: payloadBuilder
        )
        networking = RegistrarNetworkingImpl(
            networkClient: client,
            requestFactory: requestFactory
        )
    }

    func test_addOrUpdateUser() {
        // given
        prefillStorageAsVisitor()

        Mocker.register(
            Mock(
                url: url
                    .appendingPathComponent(RegistrarNetworkingRequestFactory.Constants.path)
                    .appendingPathComponent(storage.visitorID!),
                dataType: .json,
                statusCode: 200,
                data: [.post: Data()]
            )
        )

        // when
        let resultExpectation = expectation(description: "Result was not generated.")
        networking.sendToMbaas(operation: .addOrUpdateUser) { (result) in
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
                url: url
                    .appendingPathComponent(RegistrarNetworkingRequestFactory.Constants.path)
                    .appendingPathComponent(storage.customerID!),
                dataType: .json,
                statusCode: 200,
                data: [.put: Data()]
            )
        )

        // when
        let resultExpectation = expectation(description: "Result was not generated.")
        networking.sendToMbaas(operation: .migrateUser) { (result) in
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
