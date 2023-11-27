//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

public final class MockOptimoveStorage: OptimoveStorage {
    public init() {}

    public var assertFunction: ((_ value: Any?, _ key: StorageKey) -> Void)?
    public var state: [StorageKey: Any?] = [:]

    public func set(value: Any?, key: StorageKey) {
        state[key] = value
        assertFunction?(value, key)
    }

    public func value(for key: StorageKey) -> Any? {
        return state[key]
    }

    public subscript<T>(key: StorageKey) -> T? {
        get {
            return value(for: key) as? T
        }
        set(newValue) {
            set(value: newValue, key: key)
        }
    }

    var storage: [String: Data] = [:]

    public func isExist(fileName: String) -> Bool {
        return storage[fileName] != nil
    }

    public func save<T: Codable>(data: T, toFileName: String) throws {
        storage[toFileName] = try JSONEncoder().encode(data)
    }

    public func saveData(data: Data, toFileName: String) throws {
        storage[toFileName] = data
    }

    public func load<T: Codable>(fileName: String) throws -> T {
        return try JSONDecoder().decode(T.self, from: unwrap(storage[fileName]))
    }

    public func loadData(fileName: String) throws -> Data {
        return try unwrap(storage[fileName])
    }

    public func delete(fileName: String) throws {
        return storage[fileName] = nil
    }
}
