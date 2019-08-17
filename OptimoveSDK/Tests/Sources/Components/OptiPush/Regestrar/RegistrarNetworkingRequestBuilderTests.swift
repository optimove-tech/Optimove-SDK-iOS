//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import Mocker
@testable import OptimoveSDK

class RegistrarNetworkingRequestBuilderTests: XCTestCase {

    var storage: MockOptimoveStorage!
    var builder: RegistrarNetworkingRequestBuilder!

    override func setUp() {
        storage = MockOptimoveStorage()
        builder = RegistrarNetworkingRequestBuilder(
            storage: storage,
            configuration: ConfigurationFixture.build().optipush
        )
    }

    func test_registration_model_request_for_visitor() {
        // given
        let model = RegistartionMbaasModel(
            isMbaasOptIn: true,
            fcmToken: "fcmToken",
            osVersion: "osVersion",
            tenantId: 100,
            userIdPayload: BaseMbaasModel.UserIdPayload.visitorID("visitorID"),
            deviceId: "deviceId",
            appNs: "appNs"
        )

        // when
        let request = try! builder.createRequest(model: model)

        // then
        XCTAssert(request.baseURL == StubVariables.url
            .appendingPathComponent(RegistrarNetworkingRequestBuilder.Constants.Path.Operation.register + RegistrarNetworkingRequestBuilder.Constants.Path.Suffix.visitor)
        )
        XCTAssert(request.method == .post)
        XCTAssert(request.timeoutInterval == NetworkRequest.DefaultValue.timeoutInterval)
        XCTAssert(request.httpBody == (try! JSONEncoder().encode(model)))
        XCTAssert(request.headers!.contains(where: { (header) -> Bool in
            return header.field == HTTPHeader.Fields.contentType.rawValue &&
                header.value == HTTPHeader.Values.json.rawValue
        }))
    }

    func test_registration_model_request_for_customer() {
        // given
        let model = RegistartionMbaasModel(
            isMbaasOptIn: true,
            fcmToken: "fcmToken",
            osVersion: "osVersion",
            tenantId: 100,
            userIdPayload: BaseMbaasModel.UserIdPayload.customerID(
                BaseMbaasModel.UserIdPayload.CustomerIdPayload(
                    customerID: "customerID",
                    isConversion: true,
                    initialVisitorId: "initialVisitorId"
                )
            ),
            deviceId: "deviceId",
            appNs: "appNs"
        )

        // when
        let request = try! builder.createRequest(model: model)

        // then
        XCTAssert(request.baseURL == StubVariables.url
            .appendingPathComponent(RegistrarNetworkingRequestBuilder.Constants.Path.Operation.register +
                RegistrarNetworkingRequestBuilder.Constants.Path.Suffix.customer)
        )
        XCTAssert(request.method == .post)
        XCTAssert(request.timeoutInterval == NetworkRequest.DefaultValue.timeoutInterval)
        XCTAssert(request.httpBody == (try! JSONEncoder().encode(model)))
        XCTAssert(request.headers!.contains(where: { (header) -> Bool in
            return header.field == HTTPHeader.Fields.contentType.rawValue &&
                header.value == HTTPHeader.Values.json.rawValue
        }))
    }

    func test_optin_model_request_for_customer() {
        // given
        let model = MbaasModel(
            deviceId: "deviceId",
            appNs: "appNs",
            operation: .optIn,
            tenantId: 100,
            userIdPayload: BaseMbaasModel.UserIdPayload.customerID(
                BaseMbaasModel.UserIdPayload.CustomerIdPayload(
                    customerID: "customerID",
                    isConversion: true,
                    initialVisitorId: "initialVisitorId"
                )
            )
        )

        // when
        let request = try! builder.createRequest(model: model)

        // then
        XCTAssert(request.baseURL == StubVariables.url
            .appendingPathComponent(RegistrarNetworkingRequestBuilder.Constants.Path.Operation.optInOut +
                RegistrarNetworkingRequestBuilder.Constants.Path.Suffix.customer)
        )
        XCTAssert(request.method == .post)
        XCTAssert(request.timeoutInterval == NetworkRequest.DefaultValue.timeoutInterval)
        XCTAssert(request.httpBody == (try! JSONEncoder().encode(model)))
        XCTAssert(request.headers!.contains(where: { (header) -> Bool in
            return header.field == HTTPHeader.Fields.contentType.rawValue &&
                header.value == HTTPHeader.Values.json.rawValue
        }))
    }

    func test_optin_model_request_for_visitor() {
        // given
        let model = MbaasModel(
            deviceId: "deviceId",
            appNs: "appNs",
            operation: .optIn,
            tenantId: 100,
            userIdPayload: BaseMbaasModel.UserIdPayload.visitorID("visitorID")
        )

        // when
        let request = try! builder.createRequest(model: model)

        // then
        XCTAssert(request.baseURL == StubVariables.url
            .appendingPathComponent(RegistrarNetworkingRequestBuilder.Constants.Path.Operation.optInOut + RegistrarNetworkingRequestBuilder.Constants.Path.Suffix.visitor)
        )
        XCTAssert(request.method == .post)
        XCTAssert(request.timeoutInterval == NetworkRequest.DefaultValue.timeoutInterval)
        XCTAssert(request.httpBody == (try! JSONEncoder().encode(model)))
        XCTAssert(request.headers!.contains(where: { (header) -> Bool in
            return header.field == HTTPHeader.Fields.contentType.rawValue &&
                header.value == HTTPHeader.Values.json.rawValue
        }))
    }

    func test_optout_model_request_for_customer() {
        // given
        let model = MbaasModel(
            deviceId: "deviceId",
            appNs: "appNs",
            operation: .optOut,
            tenantId: 100,
            userIdPayload: BaseMbaasModel.UserIdPayload.customerID(
                BaseMbaasModel.UserIdPayload.CustomerIdPayload(
                    customerID: "customerID",
                    isConversion: true,
                    initialVisitorId: "initialVisitorId"
                )
            )
        )

        // when
        let request = try! builder.createRequest(model: model)

        // then
        XCTAssert(request.baseURL == StubVariables.url
            .appendingPathComponent(RegistrarNetworkingRequestBuilder.Constants.Path.Operation.optInOut +
                RegistrarNetworkingRequestBuilder.Constants.Path.Suffix.customer)
        )
        XCTAssert(request.method == .post)
        XCTAssert(request.timeoutInterval == NetworkRequest.DefaultValue.timeoutInterval)
        XCTAssert(request.httpBody == (try! JSONEncoder().encode(model)))
        XCTAssert(request.headers!.contains(where: { (header) -> Bool in
            return header.field == HTTPHeader.Fields.contentType.rawValue &&
                header.value == HTTPHeader.Values.json.rawValue
        }))
    }

    func test_optout_model_request_for_visitor() {
        // given
        let model = MbaasModel(
            deviceId: "deviceId",
            appNs: "appNs",
            operation: .optOut,
            tenantId: 100,
            userIdPayload: BaseMbaasModel.UserIdPayload.visitorID("visitorID")
        )

        // when
        let request = try! builder.createRequest(model: model)

        // then
        XCTAssert(request.baseURL == StubVariables.url
            .appendingPathComponent(RegistrarNetworkingRequestBuilder.Constants.Path.Operation.optInOut +
                RegistrarNetworkingRequestBuilder.Constants.Path.Suffix.visitor)
        )
        XCTAssert(request.method == .post)
        XCTAssert(request.timeoutInterval == NetworkRequest.DefaultValue.timeoutInterval)
        XCTAssert(request.httpBody == (try! JSONEncoder().encode(model)))
        XCTAssert(request.headers!.contains(where: { (header) -> Bool in
            return header.field == HTTPHeader.Fields.contentType.rawValue &&
                header.value == HTTPHeader.Values.json.rawValue
        }))
    }

    func test_unregistration_model_request_for_customer() {
        // given
        let model = MbaasModel(
            deviceId: "deviceId",
            appNs: "appNs",
            operation: .unregistration,
            tenantId: 100,
            userIdPayload: BaseMbaasModel.UserIdPayload.customerID(
                BaseMbaasModel.UserIdPayload.CustomerIdPayload(
                    customerID: "customerID",
                    isConversion: true,
                    initialVisitorId: "initialVisitorId"
                )
            )
        )

        // when
        let request = try! builder.createRequest(model: model)

        // then
        XCTAssert(request.baseURL == StubVariables.url
            .appendingPathComponent(RegistrarNetworkingRequestBuilder.Constants.Path.Operation.unregister +
                RegistrarNetworkingRequestBuilder.Constants.Path.Suffix.customer)
        )
        XCTAssert(request.method == .post)
        XCTAssert(request.timeoutInterval == NetworkRequest.DefaultValue.timeoutInterval)
        XCTAssert(request.httpBody == (try! JSONEncoder().encode(model)))
        XCTAssert(request.headers!.contains(where: { (header) -> Bool in
            return header.field == HTTPHeader.Fields.contentType.rawValue &&
                header.value == HTTPHeader.Values.json.rawValue
        }))
    }

    func test_unregistration_model_request_for_visitor() {
        // given
        let model = MbaasModel(
            deviceId: "deviceId",
            appNs: "appNs",
            operation: .unregistration,
            tenantId: 100,
            userIdPayload: BaseMbaasModel.UserIdPayload.visitorID("visitorID")
        )

        // when
        let request = try! builder.createRequest(model: model)

        // then
        XCTAssert(request.baseURL == StubVariables.url
            .appendingPathComponent(RegistrarNetworkingRequestBuilder.Constants.Path.Operation.unregister +
                RegistrarNetworkingRequestBuilder.Constants.Path.Suffix.visitor)
        )
        XCTAssert(request.method == .post)
        XCTAssert(request.timeoutInterval == NetworkRequest.DefaultValue.timeoutInterval)
        XCTAssert(request.httpBody == (try! JSONEncoder().encode(model)))
        XCTAssert(request.headers!.contains(where: { (header) -> Bool in
            return header.field == HTTPHeader.Fields.contentType.rawValue &&
                header.value == HTTPHeader.Values.json.rawValue
        }))
    }
}
