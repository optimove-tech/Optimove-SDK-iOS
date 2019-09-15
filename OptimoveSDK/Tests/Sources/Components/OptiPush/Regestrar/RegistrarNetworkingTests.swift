//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import Mocker
@testable import OptimoveSDK

class RegistrarNetworkingTests: XCTestCase {

    var networking: RegistrarNetworking!
    let url = StubVariables.url

    override func setUp() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockingURLProtocol.self]
        let client = NetworkClientImpl(configuration: configuration)
        networking = RegistrarNetworkingImpl(
            networkClient: client,
            requestBuilder: RegistrarNetworkingRequestBuilder(
                storage: MockOptimoveStorage(),
                configuration: ConfigurationFixture.build().optipush
            )
        )
    }

    func test_report_event_registration() {
        // given
        let model = MbaasModel(
            deviceId: "deviceId",
            appNs: "appNs",
            operation: .registration,
            tenantId: 100,
            userIdPayload: BaseMbaasModel.UserIdPayload.visitorID("visitorID")
        )

        Mocker.register(
            Mock(
                url: url
                    .appendingPathComponent(RegistrarNetworkingRequestBuilder.Constants.Path.Operation.register + RegistrarNetworkingRequestBuilder.Constants.Path.Suffix.visitor),
                dataType: .json,
                statusCode: 200,
                data: [.post: Data()]
            )
        )

        // when
        let resultExpectation = expectation(description: "Result was not generated.")
        networking.sendToMbaas(model: model) { (result) in
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

    func test_report_event_unregistration() {
        // given
        let model = MbaasModel(
            deviceId: "deviceId",
            appNs: "appNs",
            operation: .unregistration,
            tenantId: 100,
            userIdPayload: BaseMbaasModel.UserIdPayload.customerID(
                BaseMbaasModel.UserIdPayload.CustomerIdPayload(
                    customerID: "customerID",
                    isConversion: false,
                    initialVisitorId: "initialVisitorId"
                )
            )
        )

        Mocker.register(
            Mock(
                url: url
                    .appendingPathComponent(RegistrarNetworkingRequestBuilder.Constants.Path.Operation.unregister + RegistrarNetworkingRequestBuilder.Constants.Path.Suffix.customer),
                dataType: .json,
                statusCode: 200,
                data: [.post: Data()]
            )
        )

        // when
        let resultExpectation = expectation(description: "Result was not generated.")
        networking.sendToMbaas(model: model) { (result) in
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
