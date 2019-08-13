//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public typealias GroupedStorage = GroupedValue & FileStorage
public typealias GroupedValue = GroupedOptimoveValue & GroupKeyValueStorage

public enum GroupedStorageKey: String, CaseIterable {
    case customerID
    case configurationEndPoint
    case initialVisitorId
    case tenantToken
    case visitorID
    case version
    case userAgent
    case deviceResolutionWidth
    case deviceResolutionHeight
}

public protocol GroupedOptimoveValue {
    var customerID: String? { get set }
    var configurationEndPoint: URL? { get set }
    var initialVisitorId: String? { get set }
    var tenantToken: String? { get set }
    var visitorID: String? { get set }
    var version: String? { get set }
    var userAgent: String? { get set }
    var deviceResolutionWidth: Float? { get set }
    var deviceResolutionHeight: Float? { get set }

    func getConfigurationEndPoint() throws -> URL
    func getCustomerID() throws -> String
    func getInitialVisitorId() throws -> String
    func getTenantToken() throws -> String
    func getVisitorID() throws -> String
    func getVersion() throws -> String
    func getUserAgent() throws -> String
    func getDeviceResolutionWidth() throws -> Float
    func getDeviceResolutionHeight() throws -> Float
}

public protocol GroupKeyValueStorage {
    func set(value: Any?, key: GroupedStorageKey)
    func value(for: GroupedStorageKey) -> Any?
    subscript<T>(key: GroupedStorageKey) -> T? { get set }
}

public extension GroupKeyValueStorage where Self: GroupedOptimoveValue {

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

    func getConfigurationEndPoint() throws -> URL {
        guard let value = configurationEndPoint else {
            throw GroupedStorageError.noValue(.configurationEndPoint)
        }
        return value
    }

    func getCustomerID() throws -> String {
        guard let value = customerID else {
            throw GroupedStorageError.noValue(.customerID)
        }
        return value
    }

    func getInitialVisitorId() throws -> String {
        guard let value = initialVisitorId else {
            throw GroupedStorageError.noValue(.initialVisitorId)
        }
        return value
    }

    func getTenantToken() throws -> String {
        guard let value = tenantToken else {
            throw GroupedStorageError.noValue(.tenantToken)
        }
        return value
    }

    func getVisitorID() throws -> String {
        guard let value = visitorID else {
            throw GroupedStorageError.noValue(.visitorID)
        }
        return value
    }

    func getVersion() throws -> String {
        guard let value = version else {
            throw GroupedStorageError.noValue(.version)
        }
        return value
    }

    func getUserAgent() throws -> String {
        guard let value = userAgent else {
            throw GroupedStorageError.noValue(.userAgent)
        }
        return value
    }

    func getDeviceResolutionWidth() throws -> Float {
        guard let value = deviceResolutionWidth else {
            throw GroupedStorageError.noValue(.deviceResolutionWidth)
        }
        return value
    }

    func getDeviceResolutionHeight() throws -> Float {
        guard let value = deviceResolutionHeight else {
            throw GroupedStorageError.noValue(.deviceResolutionHeight)
        }
        return value
    }
    
}

public enum GroupedStorageError: LocalizedError {
    case noValue(GroupedStorageKey)

    public var errorDescription: String? {
        switch self {
        case let .noValue(key):
            return "GroupedStorage: No value for key \(key.rawValue)"
        }
    }
}

extension UserDefaults: GroupedValue {

    public func set(value: Any?, key: GroupedStorageKey) {
        self.set(value, forKey: key.rawValue)
    }

    public func value(for key: GroupedStorageKey) -> Any? {
        return self.value(forKey: key.rawValue)
    }

    public subscript<T>(key: GroupedStorageKey) -> T? {
        get {
            return value(for: key) as? T
        }
        set {
            set(value: newValue, key: key)
        }
    }

}