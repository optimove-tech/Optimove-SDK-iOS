//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

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

    func isExist(fileName: String) -> Bool {
        return storage[fileName] != nil
    }

    func save<T: Codable>(data: T, toFileName: String) throws {
         storage[toFileName] = try JSONEncoder().encode(data)
    }

    func saveData(data: Data, toFileName: String) throws {
        storage[toFileName] = data
    }

    func load<T: Codable>(fileName: String) throws -> T {
        return try JSONDecoder().decode(T.self, from: try unwrap(storage[fileName]))
    }

    func loadData(fileName: String) throws -> Data {
        return try unwrap(storage[fileName])
    }

    func delete(fileName: String) throws {
        return storage[fileName] = nil
    }
}
