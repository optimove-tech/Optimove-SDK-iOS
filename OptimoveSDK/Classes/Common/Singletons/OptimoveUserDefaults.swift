////
////  UserInSession.swift
////  OptimoveSDKDev
////
////  Created by Mobile Developer Optimove on 11/09/2017.
////  Copyright © 2017 Optimove. All rights reserved.
////
//
//import UIKit
//
class OptimoveUserDefaults {
    let lock: NSLock
    //
    // Use for constants that are only available inside the main application process
    let standardUserDefaults = UserDefaults.standard

    // Use for constants that are used in the shared "group.<bundle-id>.optimove" container
    let sharedUserDefaults = UserDefaults(suiteName: "group.\(Bundle.main.bundleIdentifier!).optimove")!  // If this line is crashing the client forgot to add the app group as described in the documentation
    //
    enum UserDefaultsKeys: String {
        case configurationEndPoint = "configurationEndPoint"
        case isMbaasOptIn = "isMbaasOptIn"
        case isOptiTrackOptIn = "isOptiTrackOptIn"
        case isFirstConversion = "isFirstConversion"
        case bundleIdentifier = "bundleIdentifier"
        case tenantToken = "tenantToken"
        case siteID = "siteID"
        case version = "version"
        case customerID = "customerID"
        case email = "email"
        case visitorID = "visitorID"
        case userAgent = "userAgent"
        case fcmToken = "fcmToken"
        case defaultFcmToken = "defaultFcmToken"
        case unregistrationSuccess = "unregistrationSuccess"
        case registrationSuccess = "registrationSuccess"
        case optSuccess = "optSuccess"
        case isSetUserIdSucceed = "isSetUserIdSucceed"
        case isClientHasFirebase = "userHasFirebase"
        case apnsToken = "apnsToken"
        case realtimeSetUserIdFailed = "realtimeSetUserIdFailed"
        case realtimeSetEmailFailed = "realtimeSetEmailFailed"
        case initialVisitorId = "initialVisitorId"
        case firstVisitTimestamp = "firstVisitTimestamp"
    }

    static let shared = OptimoveUserDefaults()

    private init() {
        lock = NSLock()
    }

    // MARK: Shared with App Extension

    var bundleId: String {
        get {
            return sharedUserDefaults.string(forKey: UserDefaultsKeys.bundleIdentifier.rawValue)!
        }
        set {
            self.sharedUserDefaults.set(
                Bundle.main.bundleIdentifier,
                forKey: UserDefaultsKeys.bundleIdentifier.rawValue
            )
        }
    }

    var customerID: String? {
        get {
            if let id = self.sharedUserDefaults.string(forKey: UserDefaultsKeys.customerID.rawValue) {
                return id
            }
            return nil
        }
        set {
            self.sharedUserDefaults.set(newValue, forKey: UserDefaultsKeys.customerID.rawValue)
        }
    }

    var visitorID: String? {
        get {
            if let id = self.sharedUserDefaults.string(forKey: UserDefaultsKeys.visitorID.rawValue) {
                return id
            }
            return nil
        }
        set {
            self.sharedUserDefaults.set(newValue?.lowercased(), forKey: UserDefaultsKeys.visitorID.rawValue)
        }
    }

    var initialVisitorId: String? {
        get {
            if let id = self.sharedUserDefaults.string(forKey: UserDefaultsKeys.initialVisitorId.rawValue) {
                return id
            }
            return nil
        }
        set {
            self.sharedUserDefaults.set(newValue?.lowercased(), forKey: UserDefaultsKeys.initialVisitorId.rawValue)
        }
    }

    var userAgent: String? {
        get {
            if let ua = self.sharedUserDefaults.string(forKey: UserDefaultsKeys.userAgent.rawValue) {
                return ua
            }
            return nil
        }
        set {
            self.sharedUserDefaults.set(newValue, forKey: UserDefaultsKeys.userAgent.rawValue)
            self.sharedUserDefaults.synchronize()
        }
    }

    var configurationEndPoint: String {
        get {
            if let id = self.sharedUserDefaults.string(forKey: UserDefaultsKeys.configurationEndPoint.rawValue) {
                return id
            }
            return ""
        }
        set {
            self.sharedUserDefaults.set(newValue, forKey: UserDefaultsKeys.configurationEndPoint.rawValue)
        }
    }

    var tenantToken: String? {
        get {
            if let id = self.sharedUserDefaults.string(forKey: UserDefaultsKeys.tenantToken.rawValue) {
                return id
            }
            return nil
        }
        set {
            self.sharedUserDefaults.set(newValue, forKey: UserDefaultsKeys.tenantToken.rawValue)
        }
    }

    var version: String? {
        get {
            return self.sharedUserDefaults.string(forKey: UserDefaultsKeys.version.rawValue) ?? nil
        }
        set { self.sharedUserDefaults.set(newValue, forKey: UserDefaultsKeys.version.rawValue) }
    }

    // MARK: Standard
    var userEmail: String? {
        get {
            if let id = self.standardUserDefaults.string(forKey: UserDefaultsKeys.email.rawValue) {
                return id
            }
            return nil
        }
        set {
            self.standardUserDefaults.set(newValue, forKey: UserDefaultsKeys.email.rawValue)
        }
    }

    var apnsToken: Data? {
        get {
            return self.standardUserDefaults.data(forKey: UserDefaultsKeys.apnsToken.rawValue)
        }
        set {
            if newValue == nil {
                standardUserDefaults.removeObject(forKey: UserDefaultsKeys.apnsToken.rawValue)
            } else {
                self.standardUserDefaults.set(newValue, forKey: UserDefaultsKeys.apnsToken.rawValue)
            }
        }
    }

    // MARK: Initializtion Flags

    var siteID: Int? {
        get {
            if let id = self.standardUserDefaults.value(forKey: UserDefaultsKeys.siteID.rawValue) as? Int {
                return id
            }
            return nil
        }
        set {
            self.standardUserDefaults.set(newValue, forKey: UserDefaultsKeys.siteID.rawValue)
        }
    }

    var isClientHasFirebase: Bool {
        get { return self.standardUserDefaults.bool(forKey: UserDefaultsKeys.isClientHasFirebase.rawValue) }
        set { self.standardUserDefaults.set(newValue, forKey: UserDefaultsKeys.isClientHasFirebase.rawValue) }
    }

    // MARK: Optipush Flags
    var isMbaasOptIn: Bool? {
        get {
            lock.lock()
            let val = self.standardUserDefaults.value(forKey: UserDefaultsKeys.isMbaasOptIn.rawValue) as? Bool
            lock.unlock()
            return val
        }
        set {
            lock.lock()
            standardUserDefaults.set(newValue, forKey: UserDefaultsKeys.isMbaasOptIn.rawValue)
            lock.unlock()
        }
    }

    var isUnregistrationSuccess: Bool {
        get {
            return (self.standardUserDefaults.value(forKey: UserDefaultsKeys.unregistrationSuccess.rawValue) as? Bool)
                ?? true
        }
        set {
            self.standardUserDefaults.set(newValue, forKey: UserDefaultsKeys.unregistrationSuccess.rawValue)
        }
    }

    var isRegistrationSuccess: Bool {
        get {
            return (self.standardUserDefaults.value(forKey: UserDefaultsKeys.registrationSuccess.rawValue) as? Bool)
                ?? true
        }
        set {
            self.standardUserDefaults.set(newValue, forKey: UserDefaultsKeys.registrationSuccess.rawValue)
        }
    }

    var isOptRequestSuccess: Bool {
        get {
            return (self.standardUserDefaults.value(forKey: UserDefaultsKeys.optSuccess.rawValue) as? Bool) ?? true
        }
        set {
            self.standardUserDefaults.set(newValue, forKey: UserDefaultsKeys.optSuccess.rawValue)
        }
    }

    var isFirstConversion: Bool? {
        get { return self.standardUserDefaults.value(forKey: UserDefaultsKeys.isFirstConversion.rawValue) as? Bool }
        set { self.standardUserDefaults.set(newValue, forKey: UserDefaultsKeys.isFirstConversion.rawValue) }
    }

    var defaultFcmToken: String? {
        get {
            return self.standardUserDefaults.string(forKey: UserDefaultsKeys.defaultFcmToken.rawValue) ?? nil
        }
        set {
            self.standardUserDefaults.set(newValue, forKey: UserDefaultsKeys.defaultFcmToken.rawValue)
        }
    }

    var fcmToken: String? {
        get {
            return self.standardUserDefaults.string(forKey: UserDefaultsKeys.fcmToken.rawValue) ?? nil
        }
        set {
            self.standardUserDefaults.set(newValue, forKey: UserDefaultsKeys.fcmToken.rawValue)
        }
    }

    // MARK: OptiTrack Flags
    var isOptiTrackOptIn: Bool? {
        get {
            return self.standardUserDefaults.value(forKey: UserDefaultsKeys.isOptiTrackOptIn.rawValue) as? Bool
        }
        set {
            self.standardUserDefaults.set(
                newValue,
                forKey: UserDefaultsKeys.isOptiTrackOptIn.rawValue
            )
        }
    }

    var firstVisitTimestamp: Int {
        get { return self.standardUserDefaults.integer(forKey: UserDefaultsKeys.firstVisitTimestamp.rawValue) }
        set {
            self.standardUserDefaults.set(
                newValue,
                forKey: UserDefaultsKeys.firstVisitTimestamp.rawValue
            )
        }
    }

    var isSetUserIdSucceed: Bool {
        get { return self.standardUserDefaults.bool(forKey: UserDefaultsKeys.isSetUserIdSucceed.rawValue) }

        set {
            self.standardUserDefaults.set(
                newValue,
                forKey: UserDefaultsKeys.isSetUserIdSucceed.rawValue
            )
        }
    }

    // MARK: Real time flags
    var realtimeSetUserIdFailed: Bool {
        get {
            return self.standardUserDefaults.bool(forKey: UserDefaultsKeys.realtimeSetUserIdFailed.rawValue)
        }
        set {
            self.standardUserDefaults.set(
                newValue,
                forKey: UserDefaultsKeys.realtimeSetUserIdFailed.rawValue
            )
        }
    }

    var realtimeSetEmailFailed: Bool {
        get {
            return self.standardUserDefaults.bool(forKey: UserDefaultsKeys.realtimeSetEmailFailed.rawValue)
        }
        set {
            self.standardUserDefaults.set(
                newValue,
                forKey: UserDefaultsKeys.realtimeSetEmailFailed.rawValue
            )
        }
    }
}
