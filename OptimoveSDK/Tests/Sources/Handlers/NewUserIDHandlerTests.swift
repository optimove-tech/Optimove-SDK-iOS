//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import OptimoveCore
@testable import OptimoveSDK

class NewUserIDHandlerTests: XCTestCase {

    var storage = MockOptimoveStorage()

    func test_first_login() {
        let userID = "userID"
        let expectedVisitorID = "9ef8254d9456fc23"
        let handler = NewUserIDHandler(storage: storage)

        let visitorIDExpectation = expectation(description: "visitorID was not generated")
        let customerIDExpectation = expectation(description: "customerID was not generated")
        storage.assertFunction = { (value, key) in
            if key == .visitorID {
                XCTAssertEqual(value as? String, expectedVisitorID)
                visitorIDExpectation.fulfill()
            }
            if key == .customerID {
                XCTAssertEqual(value as? String, userID)
                customerIDExpectation.fulfill()
            }
        }

        handler.handle(userID: userID)

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
        let userID = "userID"
        let expectedVisitorID = "9ef8254d9456fc23"
        let handler = NewUserIDHandler(storage: storage)

        let visitorIDExpectation = expectation(description: "visitorID was not generated")
        let customerIDExpectation = expectation(description: "customerID was not generated")
        storage.assertFunction = { (value, key) in
            if key == .visitorID {
                XCTAssertEqual(value as? String, expectedVisitorID)
                visitorIDExpectation.fulfill()
            }
            if key == .customerID {
                XCTAssertEqual(value as? String, userID)
                customerIDExpectation.fulfill()
            }
        }

        handler.handle(userID: userID)

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
        let userID = "userID"
        let expectedVisitorID = "9ef8254d9456fc23"
        let expectedConversion = false
        let handler = NewUserIDHandler(storage: storage)

        let visitorIDExpectation = expectation(description: "visitorID was not generated")
        let customerIDExpectation = expectation(description: "customerID was not generated")
        storage.assertFunction = { (value, key) in
            if key == .visitorID {
                XCTAssertEqual(value as? String, expectedVisitorID)
                visitorIDExpectation.fulfill()
            }
            if key == .customerID {
                XCTAssertEqual(value as? String, userID)
                customerIDExpectation.fulfill()
            }
        }

        handler.handle(userID: userID)

        wait(
            for: [
                visitorIDExpectation,
                customerIDExpectation,
            ],
            timeout: defaultTimeout
        )
    }

}
