//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import Mocker
@testable import OptimoveSDK

class RegistrarNetworkingRequestBuilderTests: OptimoveTestCase {

    var builder: RegistrarNetworkingRequestFactory!
    var payloadBuilder: MbaasPayloadBuilder!

    override func setUp() {
        super.setUp()
        payloadBuilder = MbaasPayloadBuilder(
            storage: storage,
            device: SDKDevice.self,
            bundle: Bundle.self
        )
        builder = RegistrarNetworkingRequestFactory(
            storage: storage,
            configuration: ConfigurationFixture.build().optipush,
            payloadBuilder: payloadBuilder
        )
    }

    func test_add_user_request_for_visitor() {
        // given
        prefillStorageAsVisitor()

        // when
        let request = try! builder.createRequest(operation: .addOrUpdateUser)

        // then
        XCTAssert(request.baseURL == StubVariables.url
            .appendingPathComponent(RegistrarNetworkingRequestFactory.Constants.path)
            .appendingPathComponent(storage.visitorID!)
        )
        XCTAssert(request.method == .post)
        XCTAssert(request.timeoutInterval == NetworkRequest.DefaultValue.timeoutInterval)
        XCTAssert(request.httpBody == (try! JSONEncoder().encode(try! payloadBuilder.createAddOrUpdateUserPayload())))
        XCTAssert(request.headers!.contains(where: { (header) -> Bool in
            return header.field == HTTPHeader.Fields.contentType.rawValue &&
                header.value == HTTPHeader.Values.json.rawValue
        }))
    }

    func test_add_user_request_for_customer() {
        // given
        prefillStorageAsCustomer()

        // when
        let request = try! builder.createRequest(operation: .addOrUpdateUser)

        // then
        XCTAssert(request.baseURL == StubVariables.url
            .appendingPathComponent(RegistrarNetworkingRequestFactory.Constants.path)
            .appendingPathComponent(storage.customerID!)
        )
        XCTAssert(request.method == .post)
        XCTAssert(request.timeoutInterval == NetworkRequest.DefaultValue.timeoutInterval)
        XCTAssert(request.httpBody == (try! JSONEncoder().encode(try! payloadBuilder.createAddOrUpdateUserPayload())))
        XCTAssert(request.headers!.contains(where: { (header) -> Bool in
            return header.field == HTTPHeader.Fields.contentType.rawValue &&
                header.value == HTTPHeader.Values.json.rawValue
        }))
    }

    func test_migrate_user_request() {
        // given
        prefillStorageAsCustomer()

        // when
        let request = try! builder.createRequest(operation: .migrateUser)

        // then
        XCTAssert(request.baseURL == StubVariables.url
            .appendingPathComponent(RegistrarNetworkingRequestFactory.Constants.path)
            .appendingPathComponent(storage.customerID!)
        )
        XCTAssert(request.method == .put)
        XCTAssert(request.timeoutInterval == NetworkRequest.DefaultValue.timeoutInterval)
        XCTAssert(request.httpBody == (try! JSONEncoder().encode(try! payloadBuilder.createMigrateUserPayload())))
        XCTAssert(request.headers!.contains(where: { (header) -> Bool in
            return header.field == HTTPHeader.Fields.contentType.rawValue &&
                header.value == HTTPHeader.Values.json.rawValue
        }))
    }
}
