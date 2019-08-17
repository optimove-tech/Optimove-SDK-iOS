//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
@testable import OptimoveCore

final class MockOptimoveStorage: OptimoveStorage {

    var assertFunction: ((_ value: Any?, _ key: StorageKey) -> Void)?
    var state: [StorageKey: Any?] = [:]

    func set(value: Any?, key: StorageKey) {
        state[key] = value
        self.assertFunction?(value, key)
    }

    func value(for key: StorageKey) -> Any? {
        return state[key]
    }

    subscript<T>(key: StorageKey) -> T? {
        get {
            return value(for: key) as? T
        }
        set(newValue) {
            set(value: newValue, key: key)
        }
    }

    var storage: [String: Data] = [:]

    func isExist(fileName: String, shared: Bool) -> Bool {
        return storage[fileName] != nil
    }

    func save<T>(data: T, toFileName: String, shared: Bool) throws where T: Encodable {
         storage[toFileName] = try JSONEncoder().encode(data)
    }

    func saveData(data: Data, toFileName: String, shared: Bool) throws {
        storage[toFileName] = data
    }

    func load(fileName: String, shared: Bool) throws -> Data {
        return try unwrap(storage[fileName])
    }

    func delete(fileName: String, shared: Bool) throws {
        return storage[fileName] = nil
    }
}
