//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public final class GroupedStorageFacade {

    // Use for constants that are used in the shared "group.<bundle-id>.optimove" container.
    private let groupedValue: GroupedValue

    private let fileStorage: FileStorage

    public init(groupedValue: GroupedValue,
         fileStorage: FileStorage) {
        self.groupedValue = groupedValue
        self.fileStorage = fileStorage
    }

}

extension GroupedStorageFacade: GroupedStorage {

    public func set(value: Any?, key: GroupedStorageKey) {
        groupedValue.set(value: value, key: key)
    }

    public func value(for key: GroupedStorageKey) -> Any? {
        return groupedValue.value(for: key)
    }

    public subscript<T>(key: GroupedStorageKey) -> T? {
        get {
            return groupedValue.value(for: key) as? T
        }
        set {
            groupedValue.set(value: newValue, key: key)
        }
    }


    public func isExist(fileName: String, shared: Bool) -> Bool {
        return fileStorage.isExist(fileName: fileName, shared: shared)
    }

    public func save<T>(data: T, toFileName: String, shared: Bool) throws where T : Encodable {
        try fileStorage.save(data: data, toFileName: toFileName, shared: shared)
    }

    public func saveData(data: Data, toFileName: String, shared: Bool) throws {
        try fileStorage.saveData(data: data, toFileName: toFileName, shared: shared)
    }

    public func load(fileName: String, shared: Bool) throws -> Data {
        return try fileStorage.load(fileName: fileName, shared: shared)
    }

    public func delete(fileName: String, shared: Bool) throws {
        try fileStorage.delete(fileName: fileName, shared: shared)
    }

}
