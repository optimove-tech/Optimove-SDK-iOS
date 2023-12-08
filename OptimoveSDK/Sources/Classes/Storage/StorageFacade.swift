//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

/// Combined protocol for a convenince access to stored values and files.
public typealias OptimoveStorage = FileStorage & KeyValueStorage & StorageValue

// MARK: - StorageCase

// MARK: - StorageKey

public enum StorageKey: String, CaseIterable {
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
    case migrationVersions /// For storing a migration history
    case firstRunTimestamp
    case pushNotificationChannels
    case optitrackEndpoint
    case tenantID
    case userEmail
    case siteID /// Legacy: See tenantID
    case settingUserSuccess
    case firstVisitTimestamp /// Legacy

    static let inMemoryValues: Set<StorageKey> = [.tenantToken, .version]
}

// MARK: - StorageValue

/// The protocol used as convenience accessor to storage values.
public protocol StorageValue {
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
    var optitrackEndpoint: URL? { get set }
    var tenantID: Int? { get set }
    var userEmail: String? { get set }
    /// Legacy: See tenantID
    var siteID: Int? { get set }
    var isSettingUserSuccess: Bool? { get set }
    /// Legacy. Use `firstRunTimestamp` instead
    var firstVisitTimestamp: Int64? { get set }

    func getConfigurationEndPoint() throws -> URL
    func getCustomerID() throws -> String
    func getInitialVisitorId() throws -> String
    func getTenantToken() throws -> String
    func getVisitorID() throws -> String
    func getVersion() throws -> String
    func getUserAgent() throws -> String
    func getDeviceResolutionWidth() throws -> Float
    func getDeviceResolutionHeight() throws -> Float
    /// Called when a migration is finished for the version.
    mutating func finishedMigration(to version: String)
    /// Use for checking if a migration was applied for the version.
    func isAlreadyMigrated(to version: String) -> Bool
    func getUserEmail() throws -> String
    func getSiteID() throws -> Int
}

/// The protocol used for convenience implementation of any storage technology below this protocol.
public protocol KeyValueStorage {
    func set(value: Any?, key: StorageKey)
    func value(for: StorageKey) -> Any?
    subscript<T>(_: StorageKey) -> T? { get set }
}

extension UserDefaults: KeyValueStorage {
    public func set(value: Any?, key: StorageKey) {
        set(value, forKey: key.rawValue)
    }

    public func value(for key: StorageKey) -> Any? {
        return value(forKey: key.rawValue)
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

public final class InMemoryStorage: KeyValueStorage {
    private var storage = [StorageKey: Any]()
    private let queue = DispatchQueue(label: "com.optimove.sdk.inmemorystorage", attributes: .concurrent)

    public init() {}

    public func set(value: Any?, key: StorageKey) {
        queue.async(flags: .barrier) { [self] in
            storage[key] = value
        }
    }

    public subscript<T>(key: StorageKey) -> T? {
        get {
            var result: T?
            queue.sync {
                result = storage[key] as? T
            }
            return result
        }
        set {
            queue.async(flags: .barrier) { [self] in
                storage[key] = newValue
            }
        }
    }

    public func value(for key: StorageKey) -> Any? {
        var result: Any?
        queue.sync {
            result = storage[key]
        }
        return result
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

/// Class implements the Façade pattern for hiding complexity of the OptimoveStorage protocol.
public final class StorageFacade: OptimoveStorage {
    private let persistantStorage: KeyValueStorage
    private let inMemoryStorage: KeyValueStorage
    private let fileStorage: FileStorage

    public init(
        persistantStorage: KeyValueStorage,
        inMemoryStorage: KeyValueStorage,
        fileStorage: FileStorage
    ) {
        self.fileStorage = fileStorage
        self.inMemoryStorage = inMemoryStorage
        self.persistantStorage = persistantStorage
    }

    func getStorage(for key: StorageKey) -> KeyValueStorage {
        if StorageKey.inMemoryValues.contains(key) {
            return inMemoryStorage
        }
        return persistantStorage
    }
}

// MARK: - KeyValueStorage

public extension StorageFacade {
    /// Use `storage.key` instead.
    /// Some variable have formatters, implemented in own setters. Set unformatted value could cause an issue.
    func set(value: Any?, key: StorageKey) {
        getStorage(for: key).set(value: value, key: key)
    }

    func value(for key: StorageKey) -> Any? {
        return getStorage(for: key).value(for: key)
    }

    subscript<T>(key: StorageKey) -> T? {
        get {
            return getStorage(for: key).value(for: key) as? T
        }
        set {
            getStorage(for: key).set(value: newValue, key: key)
        }
    }

    subscript<T>(key: StorageKey) -> () throws -> T {
        get {
            { try cast(self.getStorage(for: key).value(for: key)) }
        }
        set {
            getStorage(for: key).set(value: newValue, key: key)
        }
    }
}

// MARK: - FileStorage

public extension StorageFacade {
    func isExist(fileName: String, isTemporary: Bool) -> Bool {
        return fileStorage.isExist(fileName: fileName, isTemporary: isTemporary)
    }

    func save<T: Codable>(data: T, toFileName: String, isTemporary: Bool) throws {
        try fileStorage.save(data: data, toFileName: toFileName, isTemporary: isTemporary)
    }

    func saveData(data: Data, toFileName: String, isTemporary: Bool) throws {
        try fileStorage.saveData(data: data, toFileName: toFileName, isTemporary: isTemporary)
    }

    func load<T: Codable>(fileName: String, isTemporary: Bool) throws -> T {
        return try unwrap(fileStorage.load(fileName: fileName, isTemporary: isTemporary))
    }

    func loadData(fileName: String, isTemporary: Bool) throws -> Data {
        return try unwrap(fileStorage.loadData(fileName: fileName, isTemporary: isTemporary))
    }

    func delete(fileName: String, isTemporary: Bool) throws {
        try fileStorage.delete(fileName: fileName, isTemporary: isTemporary)
    }
}

// MARK: - StorageValue

public extension KeyValueStorage where Self: StorageValue {
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
                return try URL(string: unwrap(self[.configurationEndPoint]))
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

    var migrationVersions: [String] {
        get {
            return self[.migrationVersions] ?? []
        }
        set {
            self[.migrationVersions] = newValue
        }
    }

    var firstRunTimestamp: Int64? {
        get {
            return self[.firstRunTimestamp]
        }
        set {
            self[.firstRunTimestamp] = newValue
        }
    }

    var pushNotificationChannels: [String]? {
        get {
            return self[.pushNotificationChannels]
        }
        set {
            self[.pushNotificationChannels] = newValue
        }
    }

    var optitrackEndpoint: URL? {
        get {
            do {
                return try URL(string: unwrap(self[.optitrackEndpoint]))
            } catch {
                return nil
            }
        }
        set {
            self[.optitrackEndpoint] = newValue?.absoluteString
        }
    }

    var tenantID: Int? {
        get {
            return self[.tenantID]
        }
        set {
            self[.tenantID] = newValue
        }
    }

    var userEmail: String? {
        get {
            return self[.userEmail]
        }
        set {
            self[.userEmail] = newValue
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

    var isSettingUserSuccess: Bool? {
        get {
            return self[.settingUserSuccess]
        }
        set {
            return self[.settingUserSuccess] = newValue
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

    func getFirstRunTimestamp() throws -> Int64 {
        guard let value = firstRunTimestamp else {
            throw StorageError.noValue(.firstRunTimestamp)
        }
        return value
    }

    func getTenantID() throws -> Int {
        guard let value = tenantID else {
            throw StorageError.noValue(.tenantID)
        }
        return value
    }

    mutating func finishedMigration(to version: String) {
        var versions = migrationVersions
        versions.append(version)
        migrationVersions = versions
    }

    func isAlreadyMigrated(to version: String) -> Bool {
        return migrationVersions.contains(version)
    }

    func getUserEmail() throws -> String {
        guard let value = userEmail else {
            throw StorageError.noValue(.userEmail)
        }
        return value
    }

    func getSiteID() throws -> Int {
        guard let value = siteID else {
            throw StorageError.noValue(.siteID)
        }
        return value
    }
}
