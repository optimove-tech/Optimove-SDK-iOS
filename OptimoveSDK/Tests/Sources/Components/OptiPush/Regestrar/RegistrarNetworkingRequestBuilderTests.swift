//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import Mocker
import OptimoveCore
@testable import OptimoveSDK

class RegistrarNetworkingRequestBuilderTests: OptimoveTestCase {

    var builder: ApiRequestFactory!
    var payloadBuilder: ApiPayloadBuilder!
    let config = ConfigurationFixture.build().optipush
    let encoder = JSONEncoder()

    override func setUp() {
        super.setUp()
        payloadBuilder = ApiPayloadBuilder(
            storage: storage,
            appNamespace: try! Bundle.getApplicationNameSpace()
        )
        builder = ApiRequestFactory(
            storage: storage,
            payloadBuilder: payloadBuilder,
            requestBuilder: ApiRequestBuilder(
                optipushConfig: config
            )
        )
    }

    func test_add_user_request_for_visitor() throws {
        // given
        prefillStorageAsVisitor()
        prefillPushToken()

        // when
        let request = try builder.createRequest(operation: .setInstallation)

        // then
        XCTAssertEqual(request.baseURL, config.mbaasEndpoint
            .appendingPathComponent(ApiRequestBuilder.Constants.versionPath)
            .appendingPathComponent(ApiRequestBuilder.Constants.tenantsPath)
            .appendingPathComponent(String(config.tenantID))
            .appendingPathComponent(ApiRequestBuilder.Constants.installationPath)
        )
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.timeoutInterval, NetworkRequest.DefaultValue.timeoutInterval)
        XCTAssertEqual(request.httpBody, try encoder.encode(payloadBuilder.createInstallation()))
        XCTAssert(request.headers!.contains(where: { (header) -> Bool in
            return header.field == HTTPHeader.Fields.contentType.rawValue &&
                header.value == HTTPHeader.Values.json.rawValue
        }))
    }

    func test_add_user_request_for_customer() throws {
        // given
        prefillStorageAsCustomer()
        prefillPushToken()

        // when
        let request = try builder.createRequest(operation: .setInstallation)

        // then
        XCTAssertEqual(request.baseURL, config.mbaasEndpoint
            .appendingPathComponent(ApiRequestBuilder.Constants.versionPath)
            .appendingPathComponent(ApiRequestBuilder.Constants.tenantsPath)
            .appendingPathComponent(String(config.tenantID))
            .appendingPathComponent(ApiRequestBuilder.Constants.installationPath)
        )
        XCTAssert(request.method == .post)
        XCTAssert(request.timeoutInterval == NetworkRequest.DefaultValue.timeoutInterval)
        XCTAssertEqual(request.httpBody, try encoder.encode(payloadBuilder.createInstallation()))
        XCTAssert(request.headers!.contains(where: { (header) -> Bool in
            return header.field == HTTPHeader.Fields.contentType.rawValue &&
                header.value == HTTPHeader.Values.json.rawValue
        }))
    }

    func test_migrate_user_request() throws {
        // given
        prefillStorageAsCustomer()
        prefillPushToken()

        // when
        let request = try builder.createRequest(operation: .setInstallation)

        // then
        XCTAssertEqual(request.baseURL, config.mbaasEndpoint
            .appendingPathComponent(ApiRequestBuilder.Constants.versionPath)
            .appendingPathComponent(ApiRequestBuilder.Constants.tenantsPath)
            .appendingPathComponent(String(config.tenantID))
            .appendingPathComponent(ApiRequestBuilder.Constants.installationPath)
        )
        XCTAssert(request.method == .post)
        XCTAssert(request.timeoutInterval == NetworkRequest.DefaultValue.timeoutInterval)
        XCTAssertEqual(request.httpBody, try encoder.encode(try payloadBuilder.createInstallation()))
        XCTAssert(request.headers!.contains(where: { (header) -> Bool in
            return header.field == HTTPHeader.Fields.contentType.rawValue &&
                header.value == HTTPHeader.Values.json.rawValue
        }))
    }
}
