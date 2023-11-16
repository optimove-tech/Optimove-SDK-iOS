//  Copyright © 2019 Optimove. All rights reserved.

@testable import OptimoveSDK
import XCTest

class UserIDValidatorTests: XCTestCase {
    var storage = MockOptimoveStorage()

    func test_valid() {
        let user = User(userID: "userID")
        let validator = UserValidator(storage: storage)

        XCTAssertEqual(validator.validateNewUser(user), UserValidator.Result.valid)
    }

    func test_already_set() {
        let user = User(userID: "userID")
        storage.customerID = user.userID
        let validator = UserValidator(storage: storage)

        XCTAssertEqual(validator.validateNewUser(user), UserValidator.Result.alreadySetIn)
    }
}
