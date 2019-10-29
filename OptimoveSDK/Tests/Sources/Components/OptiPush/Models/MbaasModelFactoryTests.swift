//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

class MbaasPayloadBuilderTests: OptimoveTestCase {

    var factory: MbaasPayloadBuilder!

    override func setUp() {
        super.setUp()
        factory = MbaasPayloadBuilder(
            storage: storage,
            deviceID: SDKDevice.uuid,
            appNamespace: try! Bundle.getApplicationNameSpace(),
            tenantID: String(StubConstants.tenantID)
        )
    }

    func test_add_user_without_token() {
        // given
        prefillStorageAsVisitor()
        let expectedAppNs = try! Bundle.getApplicationNameSpace()

        // when
        let payload = factory.createSetUser()

        // then
        XCTAssertEqual(payload.deviceID, SDKDevice.uuid)
        XCTAssertEqual(payload.appNS, expectedAppNs)
        XCTAssertEqual(payload.os, SetUser.Constants.os)
        XCTAssertNil(payload.deviceToken)
        XCTAssertTrue(payload.optIn)
    }

    func test_add_user_with_token() {
        // given
        prefillStorageAsVisitor()
        let expectedAppNs = try! Bundle.getApplicationNameSpace()

        let expectedToken = Data(repeating: 42, count: 10)
        storage.apnsToken = expectedToken

        // when
        let payload = factory.createSetUser()

        // then
        XCTAssertEqual(payload.deviceID, SDKDevice.uuid)
        XCTAssertEqual(payload.appNS, expectedAppNs)
        XCTAssertEqual(payload.os, SetUser.Constants.os)
        XCTAssertNotNil(payload.deviceToken)
        XCTAssertEqual(payload.deviceToken!, expectedToken.map{ String(format: "%02.2hhx", $0) }.joined())
        XCTAssertTrue(payload.optIn)
    }

    func test_migrate_user() {
        // given
        prefillStorageAsCustomer()

        // when
        XCTAssertNoThrow(try factory.createAddUserAlias())
        let payload = try! factory.createAddUserAlias()

        // then
        XCTAssertEqual(payload.newAlias, storage.customerID!)
        XCTAssertEqual(payload.currentAlias, storage.initialVisitorId!)
    }

}
