//  Copyright © 2020 Optimove. All rights reserved.

import OptimoveCore
import OptimoveTest
@testable import OptimoveSDK
import XCTest

class EventValidatorTests: OptimoveTestCase {
    var validator: EventValidator!
    var configuration: Configuration!

    override func setUpWithError() throws {
        let builder = ConfigurationBuilder(
            globalConfig: GlobalConfigFixture().build(),
            tenantConfig: TenantConfigFixture().build()
        )
        configuration = builder.build()
        validator = EventValidator(configuration: configuration, storage: storage)
    }

    // MARK: - verifySetUserIdEvent

    func test_verifySetUserIdEvent_alreadySetInUserId_error() throws {
        let userId = "abc"
        storage.customerID = userId
        let event = SetUserIdEvent(
            originalVistorId: "original",
            userId: userId,
            updateVisitorId: ""
        )

        let errors = validator.verifySetUserIdEvent(event)
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(
            errors[0],
            ValidationError.alreadySetInUserId(userId: userId)
        )
    }

    // MARK: - verifySetEmailEvent

    func test_verifySetEmailEvent_emailAlreadySet_error() throws {
        let email = "abcABC%-90@abcABC-.abcABC"
        storage.userEmail = email
        let event = SetUserEmailEvent(email: email)
        let errors = validator.verifySetEmailEvent(event)
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(
            errors[0],
            ValidationError.alreadySetInUserEmail(email: email)
        )
    }
}
