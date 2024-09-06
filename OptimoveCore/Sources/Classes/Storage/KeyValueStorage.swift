//  Copyright © 2023 Optimove. All rights reserved.

import Foundation

/// The enum used as keys for storage values.
public enum StorageKey: String, CaseIterable {
    case installationID
    case customerID
    case configurationEndPoint
    case initialVisitorId
    case tenantToken
    case visitorID
    case version
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
    /// Kumulos
    case region
    case mediaURL
    case installUUID
    case userID
    case badgeCount
    case pendingNotifications
    case pendingAnaltics
    case inAppLastSyncedAt
    case inAppMostRecentUpdateAt
    case inAppConsented
    case dynamicCategory
    case deferredLinkChecked = "KUMULOS_DDL_CHECKED"

    public static let inMemoryValues: Set<StorageKey> = [.tenantToken, .version]
    public static let appGroupValues: Set<StorageKey> = [
        .badgeCount,
        .dynamicCategory,
        .installUUID,
        .mediaURL,
        .pendingNotifications,
        .userID,
    ]
}

/// The protocol used as convenience accessor to storage values.
public protocol StorageValue {
    var installationID: String? { get set }
    var customerID: String? { get set }
    var configurationEndPoint: URL? { get set }
    var initialVisitorId: String? { get set }
    var tenantToken: String? { get set }
    var visitorID: String? { get set }
    var version: String? { get set }
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

/// ``UserDefaults`` uses as persistent ``KeyValueStorage``.
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

/// ``InMemoryStorage`` uses as in-memory ``KeyValueStorage``.
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
