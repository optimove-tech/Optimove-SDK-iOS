//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore
@testable import OptimoveSDK
import OptimoveTest
import XCTest

class NewUserIDHandlerTests: XCTestCase {
    var storage = MockOptimoveStorage()

    func test_first_login() {
        let user = User(userID: "userID")
        let handler = NewUserHandler(storage: storage)

        let visitorIDExpectation = expectation(description: "visitorID was not generated")
        let customerIDExpectation = expectation(description: "customerID was not generated")
        storage.assertFunction = { value, key in
            if key == .visitorID {
                XCTAssertEqual(value as? String, user.visitorID)
                visitorIDExpectation.fulfill()
            }
            if key == .customerID {
                XCTAssertEqual(value as? String, user.userID)
                customerIDExpectation.fulfill()
            }
        }

        handler.handle(user: user)

        wait(
            for: [
                visitorIDExpectation,
                customerIDExpectation,
            ],
            timeout: defaultTimeout
        )
    }

    func test_second_login() {
        storage.customerID = "old_userID"
        storage.isSettingUserSuccess = true
        let user = User(userID: "userID")
        let handler = NewUserHandler(storage: storage)

        let visitorIDExpectation = expectation(description: "visitorID was not generated")
        let customerIDExpectation = expectation(description: "customerID was not generated")
        storage.assertFunction = { value, key in
            if key == .visitorID {
                XCTAssertEqual(value as? String, user.visitorID)
                visitorIDExpectation.fulfill()
            }
            if key == .customerID {
                XCTAssertEqual(value as? String, user.userID)
                customerIDExpectation.fulfill()
            }
        }

        handler.handle(user: user)

        wait(
            for: [
                visitorIDExpectation,
                customerIDExpectation,
            ],
            timeout: defaultTimeout
        )
    }

    func test_no_previous_registration_has_succeeded() {
        storage.customerID = "old_userID"
        storage.isSettingUserSuccess = false
        let user = User(userID: "userID")
        let handler = NewUserHandler(storage: storage)

        let visitorIDExpectation = expectation(description: "visitorID was not generated")
        let customerIDExpectation = expectation(description: "customerID was not generated")
        storage.assertFunction = { value, key in
            if key == .visitorID {
                XCTAssertEqual(value as? String, user.visitorID)
                visitorIDExpectation.fulfill()
            }
            if key == .customerID {
                XCTAssertEqual(value as? String, user.userID)
                customerIDExpectation.fulfill()
            }
        }

        handler.handle(user: user)

        wait(
            for: [
                visitorIDExpectation,
                customerIDExpectation,
            ],
            timeout: defaultTimeout
        )
    }
}
