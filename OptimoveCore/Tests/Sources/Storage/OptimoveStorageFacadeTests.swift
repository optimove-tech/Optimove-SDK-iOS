//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveCore

class OptimoveStorageFacadeTests: XCTestCase {

    var storage: StorageFacade!

    override func setUp() {
        storage = StorageFacade(
            keyValureStorage: MockKeyValueStorage(),
            fileStorage: MockFileStorage()
        )
    }

    func test_set_get_value() {
        // given
        let stub_string = "stub_string"
        let key: StorageKey = .apnsToken

        // when
        storage.set(value: stub_string, key: key)

        // then
        XCTAssert(storage.value(for: key) as? String == stub_string)
    }

    func test_set_get_subscript() {
        // given
        let stub_string = "stub_string"
        let key: StorageKey = .apnsToken

        // when
        storage[key] = stub_string

        // then
        let value: String? = storage[key]
        XCTAssert(value == stub_string)
    }

}
