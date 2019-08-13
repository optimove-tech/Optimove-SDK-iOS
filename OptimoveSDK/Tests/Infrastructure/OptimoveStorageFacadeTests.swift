// Copiright 2019 Optimove

import XCTest
@testable import OptimoveSDK

class OptimoveStorageFacadeTests: XCTestCase {

    var storage: OptimoveStorageFacade!


    override func setUp() {
        let dependencyStorage = MockOptimoveStorage()
        storage = OptimoveStorageFacade(
            sharedStorage: dependencyStorage,
            groupStorage: dependencyStorage,
            fileStorage: dependencyStorage
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
