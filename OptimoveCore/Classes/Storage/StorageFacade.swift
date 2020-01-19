//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

/// Combined protocol for a convenince access to stored values and files.
public typealias OptimoveStorage = KeyValueStorage & FileStorage & StorageValue

// MARK: - StorageKey

public enum StorageKey: String, CaseIterable {

    // MARK: Grouped keys
    /// Placed in optimove group container

    case installationID
    case customerID
    case configurationEndPoint
    case initialVisitorId
    case tenantToken
    case visitorID
    case version
    case userAgent
    case deviceResolutionWidth
    case deviceResolutionHeight
    case advertisingIdentifier
    case optFlag
    case failedCustomerIDs

    // MARK: Shared keys
    /// Placed in tenant container (legacy)

    case userEmail
    case apnsToken
    case siteID
    case isClientHasFirebase
    case addingUserAliasSuccess
    case settingUserSuccess
    case defaultFcmToken
    case fcmToken
    case firstVisitTimestamp
    case realtimeSetUserIdFailed
    case realtimeSetEmailFailed
}

// MARK: - StorageValue

/// The protocol used as convenience accessor to storage values.
public protocol StorageValue {

    // MARK: Grouped values

    var installationID: String? { get set }
    var customerID: String? { get set }
    var configurationEndPoint: URL? { get set }
    var initialVisitorId: String? { get set }
    var tenantToken: String? { get set }
    var visitorID: String? { get set }
    var version: String? { get set }
    var userAgent: String? { get set }
    var deviceResolutionWidth: Float? { get set }
    var deviceResolutionHeight: Float? { get set }
    var advertisingIdentifier: String? { get set }
    var optFlag: Bool { get set }
    var failedCustomerIDs: Set<String> { get set }

    func getConfigurationEndPoint() throws -> URL
    func getCustomerID() throws -> String
    func getInitialVisitorId() throws -> String
    func getTenantToken() throws -> String
    func getVisitorID() throws -> String
    func getVersion() throws -> String
    func getUserAgent() throws -> String
    func getDeviceResolutionWidth() throws -> Float
    func getDeviceResolutionHeight() throws -> Float
    func getAdvertisingIdentifier() throws -> String

    // MARK: Shared values

    var userEmail: String? { get set }
    var apnsToken: Data? { get set }
    var siteID: Int? { get set }
    /// Default value is `false`
    var isClientHasFirebase: Bool { get set }
    var isAddingUserAliasSuccess: Bool? { get set }
    var isSettingUserSuccess: Bool? { get set }
    var defaultFcmToken: String? { get set }
    var fcmToken: String? { get set }
    var firstVisitTimestamp: Int64? { get set }
    var realtimeSetUserIdFailed: Bool { get set }
    var realtimeSetEmailFailed: Bool { get set }

    func getUserEmail() throws -> String
    func getApnsToken() throws -> Data
    func getSiteID() throws -> Int
    func getDefaultFcmToken() throws -> String
    func getFcmToken() throws -> String
    func getFirstVisitTimestamp() throws -> Int64
}

/// The protocol used for convenience implementation of any storage technology below this protocol.
public protocol KeyValueStorage {
    func set(value: Any?, key: StorageKey)
    func value(for: StorageKey) -> Any?
    subscript<T>(key: StorageKey) -> T? { get set }
}

/// Class implements the Façade pattern for hiding complexity of the OptimoveStorage protocol.
public final class StorageFacade: OptimoveStorage {

    // Use for constants that are used in the grouped "group.<bundle-main-id>.optimove" container.
    private let groupedStorage: KeyValueStorage
    private let groupKeys: Set<StorageKey> = [
        .installationID,
        .customerID,
        .configurationEndPoint,
        .initialVisitorId,
        .tenantToken,
        .visitorID,
        .version,
        .userAgent,
        .deviceResolutionWidth,
        .deviceResolutionHeight,
        .advertisingIdentifier,
        .optFlag,
        .failedCustomerIDs
    ]

    // Use for constants that are used in the shared "<bundle-main-id>" container.
    private let sharedStorage: KeyValueStorage
    private let sharedKeys: Set<StorageKey> = [
        .userEmail,
        .apnsToken,
        .siteID,
        .isClientHasFirebase,
        .addingUserAliasSuccess,
        .settingUserSuccess,
        .defaultFcmToken,
        .fcmToken,
        .firstVisitTimestamp,
        .realtimeSetUserIdFailed,
        .realtimeSetEmailFailed
    ]

    private let fileStorage: FileStorage

    public init(
        groupedStorage: KeyValueStorage,
        sharedStorage: KeyValueStorage,
        fileStorage: FileStorage) {
        self.groupedStorage = groupedStorage
        self.sharedStorage = sharedStorage
        self.fileStorage = fileStorage

        let unitedKeys = sharedKeys.union(groupKeys)
        precondition(
            unitedKeys.isSuperset(of: StorageKey.allCases),
            """
            The `sharedKeys` and `groupKeys` together are not a superset of all StorageKeys.
            Missed keys: \(unitedKeys.symmetricDifference(Set(StorageKey.allCases)))
            """
        )
    }

    private func storage(for key: StorageKey) -> KeyValueStorage {
        return sharedKeys.contains(key) ? sharedStorage : groupedStorage
    }

}

// MARK: - KeyValueStorage

extension StorageFacade {

    public func set(value: Any?, key: StorageKey) {
        storage(for: key).set(value: value, key: key)
    }

    public func value(for key: StorageKey) -> Any? {
        return storage(for: key).value(for: key)
    }

    public subscript<T>(key: StorageKey) -> T? {
        get {
            return storage(for: key).value(for: key) as? T
        }
        set {
            storage(for: key).set(value: newValue, key: key)
        }
    }

/// Should be supported in the future version of Swift. https://bugs.swift.org/browse/SR-238
//    subscript<T>(key: StorageKey) -> () throws -> T {
//        get {
//            return { try cast(self.storage(for: key).value(forKey: key.rawValue)) }
//        }
//        set {
//            storage(for: key).set(newValue, forKey: key.rawValue)
//        }
//    }

}

// MARK: - FileStorage

extension StorageFacade {

    public func isExist(fileName: String, shared: Bool) -> Bool {
        return fileStorage.isExist(fileName: fileName, shared: shared)
    }

    public func save<T>(data: T, toFileName: String, shared: Bool) throws where T: Encodable {
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

// MARK: - StorageValue

public extension KeyValueStorage where Self: StorageValue {

    // MARK: Grouped values

    var installationID: String? {
        get {
            return self[.installationID]
        }
        set {
            self[.installationID] = newValue
        }
    }

    var customerID: String? {
        get {
            return self[.customerID]
        }
        set {
            self[.customerID] = newValue
        }
    }

    var visitorID: String? {
        get {
            return self[.visitorID]
        }
        set {
            self[.visitorID] = newValue?.lowercased()
        }
    }

    var initialVisitorId: String? {
        get {
            return self[.initialVisitorId]
        }
        set {
            self[.initialVisitorId] = newValue?.lowercased()
        }
    }

    var configurationEndPoint: URL? {
        get {
            do {
                return URL(string: try unwrap(self[.configurationEndPoint]))
            } catch {
                return nil
            }
        }
        set {
            self[.configurationEndPoint] = newValue?.absoluteString
        }
    }

    var tenantToken: String? {
        get {
            return self[.tenantToken]
        }
        set {
            self[.tenantToken] = newValue
        }
    }

    var version: String? {
        get {
            return self[.version]
        }
        set {
            self[.version] = newValue
        }
    }

    var userAgent: String? {
        get {
            return self[.userAgent]
        }
        set {
            self[.userAgent] = newValue
        }
    }

    var deviceResolutionWidth: Float? {
        get {
            return self[.deviceResolutionWidth]
        }
        set {
            self[.deviceResolutionWidth] = newValue
        }
    }

    var deviceResolutionHeight: Float? {
        get {
            return self[.deviceResolutionHeight]
        }
        set {
            self[.deviceResolutionHeight] = newValue
        }
    }

    var advertisingIdentifier: String? {
        get {
            return self[.advertisingIdentifier]
        }
        set {
            self[.advertisingIdentifier] = newValue
        }
    }

    var optFlag: Bool {
        get {
            return self[.optFlag] ?? false
        }
        set {
            self[.optFlag] = newValue
        }
    }

    var failedCustomerIDs: Set<String> {
        get {
            do {
                guard let data: Data = self[.failedCustomerIDs] else { return [] }
                return Set<String>(try JSONDecoder().decode([String].self, from: data))
            } catch {
                return []
            }
        }
        set {
            tryCatch {
                self[.failedCustomerIDs] = try JSONEncoder().encode(newValue)
            }
        }
    }

    // MARK: Group values getters

    func getConfigurationEndPoint() throws -> URL {
        guard let value = configurationEndPoint else {
            throw StorageError.noValue(.configurationEndPoint)
        }
        return value
    }

    func getInstallationID() throws -> String {
        guard let value = installationID else {
            throw StorageError.noValue(.installationID)
        }
        return value
    }

    func getCustomerID() throws -> String {
        guard let value = customerID else {
            throw StorageError.noValue(.customerID)
        }
        return value
    }

    func getInitialVisitorId() throws -> String {
        guard let value = initialVisitorId else {
            throw StorageError.noValue(.initialVisitorId)
        }
        return value
    }

    func getTenantToken() throws -> String {
        guard let value = tenantToken else {
            throw StorageError.noValue(.tenantToken)
        }
        return value
    }

    func getVisitorID() throws -> String {
        guard let value = visitorID else {
            throw StorageError.noValue(.visitorID)
        }
        return value
    }

    func getVersion() throws -> String {
        guard let value = version else {
            throw StorageError.noValue(.version)
        }
        return value
    }

    func getUserAgent() throws -> String {
        guard let value = userAgent else {
            throw StorageError.noValue(.userAgent)
        }
        return value
    }

    func getDeviceResolutionWidth() throws -> Float {
        guard let value = deviceResolutionWidth else {
            throw StorageError.noValue(.deviceResolutionWidth)
        }
        return value
    }

    func getDeviceResolutionHeight() throws -> Float {
        guard let value = deviceResolutionHeight else {
            throw StorageError.noValue(.deviceResolutionHeight)
        }
        return value
    }

    func getAdvertisingIdentifier() throws -> String {
        guard let value = advertisingIdentifier else {
            throw StorageError.noValue(.advertisingIdentifier)
        }
        return value
    }

    // MARK: Shared values

    var userEmail: String? {
        get {
            return self[.userEmail]
        }
        set {
            self[.userEmail] = newValue
        }
    }

    var apnsToken: Data? {
        get {
            return self[.apnsToken]
        }
        set {
            self[.apnsToken] = newValue
        }
    }

    var siteID: Int? {
        get {
            return self[.siteID]
        }
        set {
            self[.siteID] = newValue
        }
    }

    var isClientHasFirebase: Bool {
        get {
            return self[.isClientHasFirebase] ?? false
        }
        set {
            self[.isClientHasFirebase] = newValue
        }
    }

    var isAddingUserAliasSuccess: Bool? {
        get {
            return self[.addingUserAliasSuccess]
        }
        set {
            self[.addingUserAliasSuccess] = newValue
        }
    }

    var isSettingUserSuccess: Bool? {
        get {
            return self[.settingUserSuccess]
        }
        set {
            return self[.settingUserSuccess] = newValue
        }
    }

    var defaultFcmToken: String? {
        get {
            return self[.defaultFcmToken]
        }
        set {
            self[.defaultFcmToken] = newValue
        }
    }

    var fcmToken: String? {
        get {
            return self[.fcmToken]
        }
        set {
            self[.fcmToken] = newValue
        }
    }

    var firstVisitTimestamp: Int64? {
        get {
            return self[.firstVisitTimestamp]
        }
        set {
            self[.firstVisitTimestamp] = newValue
        }
    }

    var realtimeSetUserIdFailed: Bool {
        get {
            return self[.realtimeSetUserIdFailed] ?? false
        }
        set {
            self[.realtimeSetUserIdFailed] = newValue
        }
    }

    var realtimeSetEmailFailed: Bool {
        get {
            return self[.realtimeSetEmailFailed] ?? false
        }
        set {
            self[.realtimeSetEmailFailed] = newValue
        }
    }

    // MARK: Shared values getters

    func getUserEmail() throws -> String {
        guard let value = userEmail else {
            throw StorageError.noValue(.userEmail)
        }
        return value
    }

    func getApnsToken() throws -> Data {
        guard let value = apnsToken else {
            throw StorageError.noValue(.apnsToken)
        }
        return value
    }

    func getSiteID() throws -> Int {
        guard let value = siteID else {
            throw StorageError.noValue(.siteID)
        }
        return value
    }

    func getDefaultFcmToken() throws -> String {
        guard let value = defaultFcmToken else {
            throw StorageError.noValue(.defaultFcmToken)
        }
        return value
    }

    func getFcmToken() throws -> String {
        guard let value = fcmToken else {
            throw StorageError.noValue(.fcmToken)
        }
        return value
    }

    func getFirstVisitTimestamp() throws -> Int64 {
        guard let value = firstVisitTimestamp else {
            throw StorageError.noValue(.firstVisitTimestamp)
        }
        return value
    }

}

public enum StorageError: LocalizedError {
    case noValue(StorageKey)

    public var errorDescription: String? {
        switch self {
        case let .noValue(key):
            return "StorageError: No value for key \(key.rawValue)"
        }
    }
}

extension UserDefaults: KeyValueStorage {

    public func set(value: Any?, key: StorageKey) {
        self.set(value, forKey: key.rawValue)
    }

    public func value(for key: StorageKey) -> Any? {
        return self.value(forKey: key.rawValue)
    }

    public subscript<T>(key: StorageKey) -> T? {
        get {
            return value(for: key) as? T
        }
        set {
            set(value: newValue, key: key)
        }
    }

}
