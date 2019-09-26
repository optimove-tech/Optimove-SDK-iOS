//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

class MbaasPayloadBuilderTests: OptimoveTestCase {

    var factory: MbaasPayloadBuilder!

    override func setUp() {
        super.setUp()
        factory = MbaasPayloadBuilder(
            storage: storage,
            device: SDKDevice.self,
            bundle: Bundle.self
        )
    }

    func test_add_user_without_token() {
        // given
        prefillStorageAsVisitor()
        let expectedAppNs = try! Bundle.getApplicationNameSpace()

        // when
        XCTAssertNoThrow(try factory.createAddOrUpdateUserPayload())
        let payload = try! factory.createAddOrUpdateUserPayload()

        // then
        XCTAssertEqual(payload.deviceID, SDKDevice.uuid)
        XCTAssertEqual(payload.appNS, expectedAppNs)
        XCTAssertEqual(payload.os, AddOrUpdateUserPayload.Constants.os)
        XCTAssertNil(payload.pushToken)
        XCTAssertNotNil(payload.optIn)
        XCTAssertTrue(payload.optIn!)
    }

    func test_add_user_with_token() {
        // given
        prefillStorageAsVisitor()
        let expectedAppNs = try! Bundle.getApplicationNameSpace()

        let expectedToken = Data(repeating: 42, count: 10)
        storage.apnsToken = expectedToken

        // when
        XCTAssertNoThrow(try factory.createAddOrUpdateUserPayload())
        let payload = try! factory.createAddOrUpdateUserPayload()

        // then
        XCTAssertEqual(payload.deviceID, SDKDevice.uuid)
        XCTAssertEqual(payload.appNS, expectedAppNs)
        XCTAssertEqual(payload.os, AddOrUpdateUserPayload.Constants.os)
        XCTAssertNotNil(payload.pushToken)
        XCTAssertEqual(payload.pushToken!, expectedToken.map{ String(format: "%02.2hhx", $0) }.joined())
        XCTAssertNotNil(payload.optIn)
        XCTAssertTrue(payload.optIn!)
    }

    func test_migrate_user() {
        // given
        prefillStorageAsCustomer()

        // when
        XCTAssertNoThrow(try factory.createMigrateUserPayload())
        let payload = try! factory.createMigrateUserPayload()

        // then
        XCTAssertEqual(payload.newID, storage.customerID!)
        XCTAssertEqual(payload.oldID, storage.visitorID!)
    }

}
