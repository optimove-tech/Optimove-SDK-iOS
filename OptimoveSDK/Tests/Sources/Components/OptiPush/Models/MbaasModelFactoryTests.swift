//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

class MbaasPayloadBuilderTests: OptimoveTestCase {

    var factory: ApiPayloadBuilder!

    override func setUp() {
        super.setUp()
        factory = ApiPayloadBuilder(
            storage: storage,
            deviceID: SDKDevice.uuid,
            appNamespace: try! Bundle.getApplicationNameSpace()
        )
    }

    func test_add_user_without_token() {
        // given
        prefillStorageAsVisitor()

        // when
        XCTAssertThrowsError(try factory.createSetUser())
    }

    func test_add_user_with_token() {
        // given
        prefillStorageAsVisitor()
        let expectedAppNs = try! Bundle.getApplicationNameSpace()

        let expectedToken = Data(repeating: 42, count: 10)
        storage.apnsToken = expectedToken

        // when
        XCTAssertNoThrow(try factory.createSetUser())
        let payload = try! factory.createSetUser()

        // then
        XCTAssertEqual(payload.deviceID, SDKDevice.uuid)
        XCTAssertEqual(payload.appNS, expectedAppNs)
        XCTAssertEqual(payload.os, SetUser.Constants.os)
        XCTAssertNotNil(payload.deviceToken)
        XCTAssertEqual(payload.deviceToken, expectedToken.map { String(format: "%02.2hhx", $0) }.joined())
        XCTAssertFalse(payload.optIn)
    }

    func test_migrate_user() {
        // given
        prefillStorageAsCustomer()

        // when
        XCTAssertNoThrow(try factory.createAddUserAlias())
        let payload = try! factory.createAddUserAlias()

        // then
        XCTAssertEqual(payload.newAliases, [storage.customerID!])
    }

    func test_migrate_user_with_failed_payload() {
        // given
        prefillStorageAsCustomer()
        let failedCustomerIDs: Set<String> = ["a", "b", "c"]
        storage.failedCustomerIDs = failedCustomerIDs

        // when
        XCTAssertNoThrow(try factory.createAddUserAlias())
        let payload = try! factory.createAddUserAlias()

        // then

        XCTAssertEqual(Set(payload.newAliases), Set([storage.customerID!]).union(failedCustomerIDs))
    }

}
