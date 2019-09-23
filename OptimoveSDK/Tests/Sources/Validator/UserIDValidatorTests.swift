//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

class UserIDValidatorTests: XCTestCase {

    var storage = MockOptimoveStorage()

    func test_valid() {
        let userID = "userID"
        let validator = UserIDValidator(storage: storage)

        XCTAssertEqual(validator.validateNewUserID(userID), UserIDValidator.Result.valid)
    }

    func test_not_valid() {
        let userIDs = ["", "none", "undefined", "undefine", "null", "undefine_foo", "undefinebar"]
        let validator = UserIDValidator(storage: storage)

        userIDs.forEach { userID in
            XCTAssertEqual(validator.validateNewUserID(userID), UserIDValidator.Result.notValid)
        }
    }

    func test_already_set() {
        let userID = "userID"
        storage.customerID = userID
        let validator = UserIDValidator(storage: storage)

        XCTAssertEqual(validator.validateNewUserID(userID), UserIDValidator.Result.alreadySetIn)
    }

}
