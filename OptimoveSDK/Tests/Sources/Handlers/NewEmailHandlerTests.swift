//  Copyright © 2019 Optimove. All rights reserved.

@testable import OptimoveSDK
import OptimoveTest
import XCTest

class NewEmailHandlerTests: XCTestCase {
    func testExample() {
        let storage = MockOptimoveStorage()
        let handler = NewEmailHandler(storage: storage)
        let email = "a@b.c"

        storage.assertFunction = { value, key in
            XCTAssertEqual(key, .userEmail)
            XCTAssertEqual(value as? String, email)
        }

        handler.handle(email: email)
    }
}
