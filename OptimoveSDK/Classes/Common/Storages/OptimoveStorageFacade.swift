// Copiright 2019 Optimove

import Foundation
import OptimoveCore

final class OptimoveStorageFacade {

    // Use for constants that are only available inside the main application process.
    private let sharedStorage: OptimoveCarefullStorage
    private let sharedKeys: Set<SharedStorageKey> = [
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
    private let groupKeys: Set<GroupedStorageKey> = [
        .customerID,
        .configurationEndPoint,
        .initialVisitorId,
        .tenantToken,
        .visitorID,
        .version
    ]

    private let fileStorage: FileStorage

    init(sharedStorage: OptimoveCarefullStorage,
         groupStorage: OptimoveCarefullStorage,
         fileStorage: FileStorage) {
        self.sharedStorage = sharedStorage
        self.groupStorage = groupStorage
        self.fileStorage = fileStorage

        prepare()
    }

    private func prepare() {
        let careService = CareService(
            groupStorage: groupStorage,
            sharedStorage: sharedStorage
        )
        careService.makeSomeCare()
    }

}

extension OptimoveStorageFacade: OptimoveStorage {

    func set(value: Any?, key: GroupedStorageKey) {
        groupStorage.set(value: value, key: key)
    }

    func value(for key: GroupedStorageKey) -> Any? {
        return groupStorage.value(for: key)
    }

    subscript<T>(key: GroupedStorageKey) -> T? {
        get {
            return groupStorage.value(for: key) as? T
        }
        set {
            groupStorage.set(value: newValue, key: key)
        }
    }

    func set(value: Any?, key: SharedStorageKey) {
        sharedStorage.set(value: value, key: key)
    }

    func value(for key: SharedStorageKey) -> Any? {
        return sharedStorage.value(for: key)
    }

    subscript<T>(key: SharedStorageKey) -> T? {
        get {
            return sharedStorage.value(for: key) as? T
        }
        set {
            sharedStorage.set(value: newValue, key: key)
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

    func isExist(fileName: String, shared: Bool) -> Bool {
        return fileStorage.isExist(fileName: fileName, shared: shared)
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

    // MARK: - SharedKeyValueStorage

    func set(value: Any?, key: SharedStorageKey) {
        self.set(value, forKey: key.rawValue)
    }

    func value(for key: SharedStorageKey) -> Any? {
        return self.value(forKey: key.rawValue)
    }

    subscript<T>(key: SharedStorageKey) -> T? {
        get {
            return value(for: key) as? T
        }
        set {
            set(value: newValue, key: key)
        }
    }



    // MARK: - CarefullStorage

    func removeValue(forKey key: String) {
        self.removeObject(forKey: key)
    }

}
