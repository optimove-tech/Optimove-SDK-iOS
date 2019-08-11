///  Copyright © 2017 Optimove. All rights reserved.

import Foundation

typealias OptimoveStorage = OptimoveKeyValueStorage & OptimoveFileStorage
typealias OptimoveKeyValueStorage = KeyValueStorage & OptimoveValue

/// Used only for CareService
typealias OptimoveCarefullStorage = OptimoveKeyValueStorage & CarefullStorage

protocol KeyValueStorage {
    func set(value: Any?, key: StorageKey)
    func value(for: StorageKey) -> Any?
    subscript<T>(key: StorageKey) -> T? { get set }
}

protocol CarefullStorage {
    func removeValue(forKey: String)
}

enum StorageKey: String, CaseIterable {
    // MARK: - Shared with App Extension
    case customerID
    case configurationEndPoint
    case initialVisitorId
    case tenantToken
    case visitorID
    case version
    case userAgent
    // MARK: Group
    case userEmail
    case apnsToken
    // MARK: Initializtion Flags
    case siteID
    case isClientHasFirebase
    // MARK: Optipush Flags
    case isMbaasOptIn
    case unregistrationSuccess
    case registrationSuccess
    case optSuccess
    case isFirstConversion
    case defaultFcmToken
    case fcmToken
    // MARK: OptiTrack Flags
    case isOptiTrackOptIn
    case firstVisitTimestamp
    case isSetUserIdSucceed
    // MARK: Real time flags -
    case realtimeSetUserIdFailed
    case realtimeSetEmailFailed
}

protocol OptimoveValue {
    var customerID: String? { get set }
    var configurationEndPoint: String? { get set }
    var initialVisitorId: String? { get set }
    var tenantToken: String? { get set }
    var visitorID: String? { get set }
    var version: String? { get set }
    var userEmail: String? { get set }
    var apnsToken: Data? { get set }
    // MARK: Initializtion Flags
    var siteID: Int? { get set }
    var isClientHasFirebase: Bool { get set }
    // MARK: Optipush Flags
    var isMbaasOptIn: Bool? { get set }
    var isUnregistrationSuccess: Bool { get set }
    var isRegistrationSuccess: Bool { get set }
    var isOptRequestSuccess: Bool { get set }
    var isFirstConversion: Bool { get set }
    var defaultFcmToken: String? { get set }
    var fcmToken: String? { get set }
    // MARK: OptiTrack Flags
    var isOptiTrackOptIn: Bool { get set }
    var firstVisitTimestamp: Int? { get set }
    var isSetUserIdSucceed: Bool { get set }
    // MARK: Real time flags
    var realtimeSetUserIdFailed: Bool { get set }
    var realtimeSetEmailFailed: Bool { get set }

    // A value accessor that throws an error.
    func getConfigurationEndPoint() throws -> String
    func getCustomerID() throws -> String
    func getInitialVisitorId() throws -> String
    func getTenantToken() throws -> String
    func getVisitorID() throws -> String
    func getVersion() throws -> String
    func getUserEmail() throws -> String
    func getApnsToken() throws -> Data
    func getSiteID() throws -> Int
    func getIsMbaasOptIn() throws -> Bool
    func getDefaultFcmToken() throws -> String
    func getFcmToken() throws -> String
    func getFirstVisitTimestamp() throws -> Int
}

private let lock = UnfairLock()

extension KeyValueStorage where Self: OptimoveValue {

    // MARK: Shared with App Extension

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
    
    var configurationEndPoint: String? {
        get {
            return self[.configurationEndPoint]
        }
        set {
            self[.configurationEndPoint] = newValue
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
    
    
    // MARK: Standard
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
    
    // MARK: Initializtion Flags
    
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
    
    // MARK: Optipush Flags

    var isMbaasOptIn: Bool? {
        get {
            return lock.sync {
                return self[.isMbaasOptIn]
            }
        }
        set {
            lock.sync {
                self[.isMbaasOptIn] = newValue
            }
        }
    }
    
    var isUnregistrationSuccess: Bool {
        get {
            return self[.unregistrationSuccess] ?? true
        }
        set {
            self[.unregistrationSuccess] = newValue
        }
    }
    
    var isRegistrationSuccess: Bool {
        get {
            return self[.registrationSuccess] ?? true
        }
        set {
            return self[.registrationSuccess] = newValue
        }
    }
    
    var isOptRequestSuccess: Bool {
        get {
            return self[.optSuccess] ?? true
        }
        set {
            return self[.optSuccess] = newValue
        }
    }
    
    var isFirstConversion: Bool {
        get {
            return self[.isFirstConversion] ?? false
        }
        set {
            return self[.isFirstConversion] = newValue
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
    
    // MARK: OptiTrack Flags
    var isOptiTrackOptIn: Bool {
        get {
            return self[.isOptiTrackOptIn] ?? false
        }
        set {
            self[.isOptiTrackOptIn] = newValue
        }
    }
    
    var firstVisitTimestamp: Int? {
        get {
            return self[.firstVisitTimestamp]
        }
        set {
            self[.firstVisitTimestamp] = newValue
        }
    }
    
    var isSetUserIdSucceed: Bool {
        get {
            return self[.isSetUserIdSucceed] ?? false
        }
        set {
            self[.isSetUserIdSucceed] = newValue
        }
    }
    
    // MARK: Real time flags
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

    func getConfigurationEndPoint() throws -> String {
        guard let value = configurationEndPoint else {
            throw OptimoveStorageError.noValue(.configurationEndPoint)
        }
        return value
    }

    func getCustomerID() throws -> String {
        guard let value = customerID else {
            throw OptimoveStorageError.noValue(.customerID)
        }
        return value
    }

    func getInitialVisitorId() throws -> String {
        guard let value = initialVisitorId else {
            throw OptimoveStorageError.noValue(.initialVisitorId)
        }
        return value
    }

    func getTenantToken() throws -> String {
        guard let value = tenantToken else {
            throw OptimoveStorageError.noValue(.tenantToken)
        }
        return value
    }

    func getVisitorID() throws -> String {
        guard let value = visitorID else {
            throw OptimoveStorageError.noValue(.visitorID)
        }
        return value
    }

    func getVersion() throws -> String {
        guard let value = version else {
            throw OptimoveStorageError.noValue(.version)
        }
        return value
    }

    func getUserEmail() throws -> String {
        guard let value = userEmail else {
            throw OptimoveStorageError.noValue(.userEmail)
        }
        return value
    }

    func getApnsToken() throws -> Data {
        guard let value = apnsToken else {
            throw OptimoveStorageError.noValue(.apnsToken)
        }
        return value
    }

    func getSiteID() throws -> Int {
        guard let value = siteID else {
            throw OptimoveStorageError.noValue(.siteID)
        }
        return value
    }

    func getIsMbaasOptIn() throws -> Bool {
        guard let value = isMbaasOptIn else {
            throw OptimoveStorageError.noValue(.isMbaasOptIn)
        }
        return value
    }

    func getDefaultFcmToken() throws -> String {
        guard let value = defaultFcmToken else {
            throw OptimoveStorageError.noValue(.defaultFcmToken)
        }
        return value
    }

    func getFcmToken() throws -> String {
        guard let value = fcmToken else {
            throw OptimoveStorageError.noValue(.fcmToken)
        }
        return value
    }

    func getFirstVisitTimestamp() throws -> Int {
        guard let value = firstVisitTimestamp else {
            throw OptimoveStorageError.noValue(.firstVisitTimestamp)
        }
        return value
    }
}

enum OptimoveStorageError: LocalizedError {
    case noValue(StorageKey)

    var errorDescription: String? {
        switch self {
        case let .noValue(key):
            return "OptimoveStorage: No value for key \(key.rawValue)"
        }
    }
}
