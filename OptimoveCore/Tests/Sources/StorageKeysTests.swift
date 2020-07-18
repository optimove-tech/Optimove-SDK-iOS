//  Copyright © 2020 Optimove. All rights reserved.

import XCTest
@testable import OptimoveCore

class StorageKeysTests: XCTestCase {

    func test_that_all_keys_are_known_is_storage() throws {
        let unitedKeys = StorageFacade.sharedKeys.union(StorageFacade.groupKeys)
        XCTAssert(
            unitedKeys.isSuperset(of: StorageKey.allCases),
            """
            The `sharedKeys` and `groupKeys` together are not a superset of all StorageKeys.
            Missed keys: \(unitedKeys.symmetricDifference(Set(StorageKey.allCases)))
            """
        )
    }

}
