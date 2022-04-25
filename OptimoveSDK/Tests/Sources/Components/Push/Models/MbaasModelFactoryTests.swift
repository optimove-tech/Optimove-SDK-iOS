//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

class ApiPayloadBuilderTests: OptimoveTestCase {

    var factory: ApiPayloadBuilder!

    override func setUp() {
        super.setUp()
        factory = ApiPayloadBuilder(
            storage: storage,
            appNamespace: try! Bundle.getApplicationNameSpace()
        )
    }

    func test_set_installation_without_token() {
        // given
        prefillStorageAsVisitor()

        // when
        XCTAssertThrowsError(try factory.createInstallation())
    }

    func test_add_user_with_token() {
        // given
        prefillStorageAsVisitor()
        let expectedAppNs = try! Bundle.getApplicationNameSpace()
        let expectedInstallationID = try! storage.getInstallationID()

        let expectedToken = Data(repeating: 42, count: 10)
        storage.apnsToken = expectedToken

        // when
        XCTAssertNoThrow(try factory.createInstallation())
        let payload = try! factory.createInstallation()

        // then
        XCTAssertEqual(payload.installationID, expectedInstallationID)
        XCTAssertEqual(payload.appNS, expectedAppNs)
        XCTAssertEqual(payload.os, Installation.Constants.os)
        XCTAssertNotNil(payload.deviceToken)
        XCTAssertEqual(payload.deviceToken, expectedToken.map { String(format: "%02.2hhx", $0) }.joined())
        XCTAssertFalse(payload.optIn)
    }

}
