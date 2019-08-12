///  Copyright © 2017 Optimove. All rights reserved.

import Foundation
import OptimoveCore

typealias OptimoveStorage = SharedValue & GroupedValue & FileStorage
typealias OptimoveCarefullStorage = SharedValue & GroupedValue & CarefullStorage
typealias SharedStorage = SharedValue & FileStorage
typealias SharedValue = SharedKeyValueStorage & SharedOptimoveValue

protocol CarefullStorage {
    func removeValue(forKey: String)
}

protocol SharedKeyValueStorage {
    func set(value: Any?, key: SharedStorageKey)
    func value(for: SharedStorageKey) -> Any?
    subscript<T>(key: SharedStorageKey) -> T? { get set }
}

enum SharedStorageKey: String, CaseIterable {
    case userEmail
    case apnsToken
    case siteID
    case isClientHasFirebase
    case isMbaasOptIn
    case unregistrationSuccess
    case registrationSuccess
    case optSuccess
    case isFirstConversion
    case defaultFcmToken
    case fcmToken
    case isOptiTrackOptIn
    case firstVisitTimestamp
    case isSetUserIdSucceed
    case realtimeSetUserIdFailed
    case realtimeSetEmailFailed
}

protocol SharedOptimoveValue {
    var userEmail: String? { get set }
    var apnsToken: Data? { get set }
    var siteID: Int? { get set }
    var isClientHasFirebase: Bool { get set }
    var isMbaasOptIn: Bool? { get set }
    var isUnregistrationSuccess: Bool { get set }
    var isRegistrationSuccess: Bool { get set }
    var isOptRequestSuccess: Bool { get set }
    var isFirstConversion: Bool { get set }
    var defaultFcmToken: String? { get set }
    var fcmToken: String? { get set }
    var isOptiTrackOptIn: Bool { get set }
    var firstVisitTimestamp: Int? { get set }
    var isSetUserIdSucceed: Bool { get set }
    var realtimeSetUserIdFailed: Bool { get set }
    var realtimeSetEmailFailed: Bool { get set }

    func getUserEmail() throws -> String
    func getApnsToken() throws -> Data
    func getSiteID() throws -> Int
    func getIsMbaasOptIn() throws -> Bool
    func getDefaultFcmToken() throws -> String
    func getFcmToken() throws -> String
    func getFirstVisitTimestamp() throws -> Int
}

private let lock = UnfairLock()

extension SharedKeyValueStorage where Self: SharedOptimoveValue {

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

    func getUserEmail() throws -> String {
        guard let value = userEmail else {
            throw SharedStorageError.noValue(.userEmail)
        }
        return value
    }

    func getApnsToken() throws -> Data {
        guard let value = apnsToken else {
            throw SharedStorageError.noValue(.apnsToken)
        }
        return value
    }

    func getSiteID() throws -> Int {
        guard let value = siteID else {
            throw SharedStorageError.noValue(.siteID)
        }
        return value
    }

    func getIsMbaasOptIn() throws -> Bool {
        guard let value = isMbaasOptIn else {
            throw SharedStorageError.noValue(.isMbaasOptIn)
        }
        return value
    }

    func getDefaultFcmToken() throws -> String {
        guard let value = defaultFcmToken else {
            throw SharedStorageError.noValue(.defaultFcmToken)
        }
        return value
    }

    func getFcmToken() throws -> String {
        guard let value = fcmToken else {
            throw SharedStorageError.noValue(.fcmToken)
        }
        return value
    }

    func getFirstVisitTimestamp() throws -> Int {
        guard let value = firstVisitTimestamp else {
            throw SharedStorageError.noValue(.firstVisitTimestamp)
        }
        return value
    }
}

enum SharedStorageError: LocalizedError {
    case noValue(SharedStorageKey)

    var errorDescription: String? {
        switch self {
        case let .noValue(key):
            return "SharedStorage: No value for key \(key.rawValue)"
        }
    }
}
