// Copiright 2019 Optimove

import Foundation

final class OptimoveStorageFacade {

    // Use for constants that are only available inside the main application process.
    private let sharedStorage: OptimoveCarefullStorage
    private let sharedKeys: Set<StorageKey> = [
        .userEmail,
        .apnsToken,
        .siteID,
        .isClientHasFirebase,
        .isMbaasOptIn,
        .unregistrationSuccess,
        .registrationSuccess,
        .optSuccess,
        .isFirstConversion,
        .defaultFcmToken,
        .fcmToken,
        .isOptiTrackOptIn,
        .firstVisitTimestamp,
        .isSetUserIdSucceed,
        .realtimeSetUserIdFailed,
        .realtimeSetEmailFailed,
    ]

    // Use for constants that are used in the shared "group.<bundle-id>.optimove" container.
    private let groupStorage: OptimoveCarefullStorage
    private let groupKeys: Set<StorageKey> = [
        .customerID,
        .configurationEndPoint,
        .initialVisitorId,
        .tenantToken,
        .visitorID,
        .version,
        .userAgent
    ]

    private let fileStorage: OptimoveFileStorage

    init(sharedStorage: OptimoveCarefullStorage,
         groupStorage: OptimoveCarefullStorage,
         fileStorage: OptimoveFileStorage) {
        self.sharedStorage = sharedStorage
        self.groupStorage = groupStorage
        self.fileStorage = fileStorage

        precondition(
            sharedKeys.union(groupKeys).isSuperset(of: StorageKey.allCases),
            "A `sharedKeys` and `groupKeys` together are not a superset of all StorageKeys"
        )
        prepare()
    }

    private func prepare() {
        let careService = CareService(
            groupStorage: groupStorage,
            sharedStorage: sharedStorage
        )
        careService.makeSomeCare()
    }

    private func storage(for key: StorageKey) -> OptimoveKeyValueStorage {
        return sharedKeys.contains(key) ? sharedStorage : groupStorage
    }

}

extension OptimoveStorageFacade: OptimoveStorage {

    func set(value: Any?, key: StorageKey) {
        storage(for: key).set(value: value, key: key)
    }

    func value(for key: StorageKey) -> Any? {
        return storage(for: key).value(for: key)
    }

    subscript<T>(key: StorageKey) -> T? {
        get {
            return storage(for: key).value(for: key) as? T
        }
        set {
            storage(for: key).set(value: newValue, key: key)
        }
    }

    // ELI: Should be supported in the future version of Swift. https://bugs.swift.org/browse/SR-238
    //    subscript<T>(key: UserDefaultsKey) -> () throws -> T {
    //        get {
    //            return { try cast(self.storage(for: key).value(forKey: key.rawValue)) }
    //        }
    //        set {
    //            storage(for: key).set(newValue, forKey: key.rawValue)
    //        }
    //    }

    // MARK: - OptimoveFileStorage

    func isExist(fileName: String, shared: Bool) throws -> Bool {
        return try fileStorage.isExist(fileName: fileName, shared: shared)
    }

    func save<T>(data: T, toFileName: String, shared: Bool) throws where T : Encodable {
        try fileStorage.save(data: data, toFileName: toFileName, shared: shared)
    }

    func saveData(data: Data, toFileName: String, shared: Bool) throws {
        try fileStorage.saveData(data: data, toFileName: toFileName, shared: shared)
    }

    func load(fileName: String, shared: Bool) throws -> Data {
        return try fileStorage.load(fileName: fileName, shared: shared)
    }

    func delete(fileName: String, shared: Bool) throws {
        try fileStorage.delete(fileName: fileName, shared: shared)
    }

}


extension UserDefaults: OptimoveCarefullStorage {

    func set(value: Any?, key: StorageKey) {
        self.set(value, forKey: key.rawValue)
    }

    func value(for key: StorageKey) -> Any? {
        return self.value(forKey: key.rawValue)
    }

    subscript<T>(key: StorageKey) -> T? {
        get {
            return value(for: key) as? T
        }
        set {
            set(value: newValue, key: key)
        }
    }

    func removeValue(forKey key: String) {
        self.removeObject(forKey: key)
    }

}
