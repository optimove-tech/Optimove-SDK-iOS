//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import Mocker
@testable import OptimoveSDK

class RegistrarNetworkingRequestBuilderTests: OptimoveTestCase {

    var builder: RegistrarNetworkingRequestFactory!
    var payloadBuilder: MbaasPayloadBuilder!
    let config = ConfigurationFixture.build().optipush

    override func setUp() {
        super.setUp()
        payloadBuilder = MbaasPayloadBuilder(
            storage: storage,
            deviceID: SDKDevice.uuid,
            appNamespace: try! Bundle.getApplicationNameSpace(),
            tenantID: String(StubConstants.tenantID)
        )
        builder = RegistrarNetworkingRequestFactory(
            storage: storage,
            payloadBuilder: payloadBuilder,
            requestBuilder: ClientAPIRequestBuilder(
                optipushConfig: config
            )
        )
    }

    func test_add_user_request_for_visitor() {
        // given
        prefillStorageAsVisitor()

        // when
        let request = try! builder.createRequest(operation: .setUser)

        // then
        XCTAssertEqual(request.baseURL, config.registrationServiceEndpoint
            .appendingPathComponent(ClientAPIRequestBuilder.Constants.path)
            .appendingPathComponent(storage.initialVisitorId!)
        )
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.timeoutInterval, NetworkRequest.DefaultValue.timeoutInterval)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        XCTAssertEqual(request.httpBody, try! encoder.encode(payloadBuilder.createSetUser()))
        XCTAssert(request.headers!.contains(where: { (header) -> Bool in
            return header.field == HTTPHeader.Fields.contentType.rawValue &&
                header.value == HTTPHeader.Values.json.rawValue
        }))
    }

    func test_add_user_request_for_customer() {
        // given
        prefillStorageAsCustomer()

        // when
        let request = try! builder.createRequest(operation: .setUser)

        // then
        XCTAssertEqual(request.baseURL, config.mbaasEndpoint
            .appendingPathComponent(ClientAPIRequestBuilder.Constants.path)
            .appendingPathComponent(storage.initialVisitorId!)
        )
        XCTAssert(request.method == .post)
        XCTAssert(request.timeoutInterval == NetworkRequest.DefaultValue.timeoutInterval)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        XCTAssertEqual(request.httpBody, try! encoder.encode(payloadBuilder.createSetUser()))
        XCTAssert(request.headers!.contains(where: { (header) -> Bool in
            return header.field == HTTPHeader.Fields.contentType.rawValue &&
                header.value == HTTPHeader.Values.json.rawValue
        }))
    }

    func test_migrate_user_request() {
        // given
        prefillStorageAsCustomer()

        // when
        let request = try! builder.createRequest(operation: .addUserAlias)

        // then
        XCTAssertEqual(request.baseURL, config.mbaasEndpoint
            .appendingPathComponent(ClientAPIRequestBuilder.Constants.path)
        )
        XCTAssert(request.method == .put)
        XCTAssert(request.timeoutInterval == NetworkRequest.DefaultValue.timeoutInterval)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        XCTAssertEqual(request.httpBody, try! encoder.encode(try! payloadBuilder.createAddUserAlias()))
        XCTAssert(request.headers!.contains(where: { (header) -> Bool in
            return header.field == HTTPHeader.Fields.contentType.rawValue &&
                header.value == HTTPHeader.Values.json.rawValue
        }))
    }
}
