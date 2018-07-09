//
//  UserInSession.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 11/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import UIKit

class OptimoveUserDefaults: Synchronizable
{
    let lock:NSLock
    
    // Use for constants that are only available inside the main application process
    let standardUserDefaults = UserDefaults.standard
    
    // Use for constants that are used in the shared "group.<bundle-id>.optimove" container
    let sharedUserDefaults = UserDefaults(suiteName: "group.\(Bundle.main.bundleIdentifier!).optimove")! // If this line is crashing the client forgot to add the app group as described in the documentation
    
    enum UserDefaultsKeys: String
    {
        case configurationEndPoint              = "configurationEndPoint"
        case isMbaasOptIn                       = "isMbaasOptIn"
        case isOptiTrackOptIn                   = "isOptiTrackOptIn"
        case isFirstConversion                  = "isFirstConversion"
        case tenantToken                        = "tenantToken"
        case siteID                             = "siteID"
        case version                            = "version"
        case customerID                         = "customerID"
        case visitorID                          = "visitorID"
        case userAgent                          = "userAgent"
        case deviceToken                        = "deviceToken"
        case fcmToken                           = "fcmToken"
        case defaultFcmToken                    = "defaultFcmToken"
        case isFirstLaunch                      = "isFirstLaunch"
        case userAgentHeader                    = "userAgentHeader"
        case unregistrationSuccess              = "unregistrationSuccess"
        case registrationSuccess                = "registrationSuccess"
        case optSuccess                         = "optSuccess"
        case isSetUserIdSucceed                 = "isSetUserIdSucceed"
        case isClientHasFirebase                = "userHasFirebase"
        case isClientUseFirebaseMessaging       = "isClientUseFirebaseMessaging"
        case apnsToken                          = "apnsToken"
        case hasConfigurationFile               = "hasConfigurationFile"
        case topics                             = "topic"
        case openAppTime                        = "openAppTime"
        case clientUseBackgroundExecution       = "clientUseBackgroundExecution"
        case lastPingTime                       = "lastPingTime"
        case realtimeSetUserIdFailed            = "realtimeSetUserIdFailed"
        case realtimeFailedEmail                = "realtimeFailedEmail"
        case realtimeSetEmailFailed             = "realtimeSetEmailFailed"
        case realtimeFailedOriginalVisitorId    = "realtimeFailedOriginalVisitorId"
        case initialVisitorId                   = "initialVisitorId"
        case deviceOs                           = "deviceOs"
        case deviceResolutionWidth              = "deviceResolutionWidth"
        case deviceResolutionHeight             = "deviceResolutionHeight"
        case firstVisitTimestamp                = "firstVisitTimestamp"
    }
    
    static let shared = OptimoveUserDefaults()
    private init()
    {
        lock = NSLock()
    }
    
    //MARK: Persist data
    var customerID:String?
    {
        get
        {
            if let id = self.sharedUserDefaults.string(forKey: UserDefaultsKeys.customerID.rawValue)
            {
                return id
            }
            return nil
        }
        set
        {
            self.sharedUserDefaults.set(newValue, forKey: UserDefaultsKeys.customerID.rawValue)
            self.sharedUserDefaults.synchronize()
        }
    }
    var visitorID:String?
    {
        get
        {
            if let id = self.sharedUserDefaults.string(forKey: UserDefaultsKeys.visitorID.rawValue)
            {
                return id
            }
            return nil
        }
        set
        {
            self.sharedUserDefaults.set(newValue, forKey: UserDefaultsKeys.visitorID.rawValue)
            self.sharedUserDefaults.synchronize()
        }
    }
    var initialVisitorId: String?
    {
        get
        {
            if let id = self.sharedUserDefaults.string(forKey: UserDefaultsKeys.initialVisitorId.rawValue)
            {
                return id
            }
            return nil
        }
        set
        {
            self.sharedUserDefaults.set(newValue, forKey: UserDefaultsKeys.initialVisitorId.rawValue)
            self.sharedUserDefaults.synchronize()
        }
    }
    var userAgent:String?
    {
        get
        {
            if let ua = self.sharedUserDefaults.string(forKey: UserDefaultsKeys.userAgent.rawValue)
            {
                return ua
            }
            return nil
        }
        set
        {
            self.sharedUserDefaults.set(newValue, forKey: UserDefaultsKeys.userAgent.rawValue)
            self.sharedUserDefaults.synchronize()
        }
    }
    var apnsToken: Data?
    {
        get
        {
            return self.standardUserDefaults.data(forKey: UserDefaultsKeys.apnsToken.rawValue)
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any, key: UserDefaultsKeys.apnsToken.rawValue)
        }
    }
    
    var deviceOs:String
    {
        get
        {
            if let os = self.sharedUserDefaults.string(forKey: UserDefaultsKeys.deviceOs.rawValue)  {
                return os
            }
            let os = UIDevice.current.systemVersion
            self.sharedUserDefaults.set(os, forKey: UserDefaultsKeys.deviceOs.rawValue)
            self.sharedUserDefaults.synchronize()
            return os
        }
    }
    
    
    
    var deviceResolutionWidth:Double
    {
        get
        {
            var size = self.sharedUserDefaults.double(forKey: UserDefaultsKeys.deviceResolutionWidth.rawValue)
            if size > 0 {
                return size
            }
            size = Double(UIScreen.main.bounds.size.width)
            self.sharedUserDefaults.set(size, forKey: UserDefaultsKeys.deviceResolutionWidth.rawValue)
            self.sharedUserDefaults.synchronize()
            return size
        }
    }
    var deviceResolutionHeight:Double
    {
        get
        {
            var size = self.sharedUserDefaults.double(forKey: UserDefaultsKeys.deviceResolutionHeight.rawValue)
            if size > 0 {
                return size
            }
            size = Double(UIScreen.main.bounds.size.height)
            self.sharedUserDefaults.set(size, forKey: UserDefaultsKeys.deviceResolutionHeight.rawValue)
            self.sharedUserDefaults.synchronize()
            return size
        }
    }
    
    
    //MARK: Initializtion Flags
    var configurationEndPoint: String
    {
        get
        {
            if let id = self.standardUserDefaults.string(forKey: UserDefaultsKeys.configurationEndPoint.rawValue)
            {
                return id
            }
            return ""
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any,
                                  key: UserDefaultsKeys.configurationEndPoint.rawValue)
        }
    }
    var siteID:Int?
    {
        get
        {
            if let id = self.standardUserDefaults.value(forKey: UserDefaultsKeys.siteID.rawValue) as? Int
            {
                return id
            }
            return nil
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any, key: UserDefaultsKeys.siteID.rawValue)
        }
    }
    var tenantToken: String?
    {
        get
        {
            if let id = self.standardUserDefaults.string(forKey: UserDefaultsKeys.tenantToken.rawValue)
            {
                return id
            }
            return nil
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any, key: UserDefaultsKeys.tenantToken.rawValue)
        }
    }
    var version:String?
    {
        get
        {
            if let id = self.standardUserDefaults.string(forKey: UserDefaultsKeys.version.rawValue) {
                return id
            }
            return nil
        }
        set { self.setDefaultObject(forObject: newValue as Any,
                                    key: UserDefaultsKeys.version.rawValue) }
    }
    var hasConfigurationFile : Bool?
    {
        get
        {
            return self.standardUserDefaults.value(forKey: UserDefaultsKeys.hasConfigurationFile.rawValue) as? Bool
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any,
                                  key: UserDefaultsKeys.hasConfigurationFile.rawValue)
        }
    }
    var isClientHasFirebase : Bool
    {
        get { return self.standardUserDefaults.bool(forKey: UserDefaultsKeys.isClientHasFirebase.rawValue)}
        set { self.setDefaultObject(forObject: newValue as Any,
                                    key: UserDefaultsKeys.isClientHasFirebase.rawValue) }
    }
    var isClientUseFirebaseMessaging : Bool
    {
        get { return self.standardUserDefaults.bool(forKey: UserDefaultsKeys.isClientUseFirebaseMessaging.rawValue)}
        set { self.setDefaultObject(forObject: newValue as Any,
                                    key: UserDefaultsKeys.isClientUseFirebaseMessaging.rawValue) }
    }
    
    
    // MARK: Optipush Flags
    var isMbaasOptIn: Bool?
    {
        get
        {
            lock.lock()
            let val = self.standardUserDefaults.value(forKey: UserDefaultsKeys.isMbaasOptIn.rawValue) as? Bool
            lock.unlock()
            return val
        }
        set
        {
            lock.lock()
            self.setDefaultObject(forObject: newValue as Any,
                                  key: UserDefaultsKeys.isMbaasOptIn.rawValue)
            lock.unlock()
        }
    }
    var isUnregistrationSuccess : Bool
    {
        get
        {
            return (self.standardUserDefaults.value(forKey: UserDefaultsKeys.unregistrationSuccess.rawValue) as? Bool) ?? true
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any,
                                  key: UserDefaultsKeys.unregistrationSuccess.rawValue)
        }
    }
    var isRegistrationSuccess : Bool
    {
        get
        {
            return (self.standardUserDefaults.value(forKey: UserDefaultsKeys.registrationSuccess.rawValue) as? Bool) ?? true
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any,
                                  key: UserDefaultsKeys.registrationSuccess.rawValue)
        }
    }
    var isOptRequestSuccess : Bool
    {
        get
        {
            return (self.standardUserDefaults.value(forKey: UserDefaultsKeys.optSuccess.rawValue) as? Bool) ?? true
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any,
                                  key: UserDefaultsKeys.optSuccess.rawValue)
        }
    }
    
    var isFirstConversion : Bool?
    {
        get { return self.standardUserDefaults.value(forKey: UserDefaultsKeys.isFirstConversion.rawValue) as? Bool }
        set { self.setDefaultObject(forObject: newValue as Any,
                                    key: UserDefaultsKeys.isFirstConversion.rawValue) }
    }
    var defaultFcmToken: String?
    {
        get
        {
            return self.standardUserDefaults.string(forKey: UserDefaultsKeys.defaultFcmToken.rawValue) ?? nil
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any, key: UserDefaultsKeys.defaultFcmToken.rawValue)
        }
    }
    var fcmToken: String?
    {
        get
        {
            return self.standardUserDefaults.string(forKey: UserDefaultsKeys.fcmToken.rawValue) ?? nil
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any, key: UserDefaultsKeys.fcmToken.rawValue)
        }
    }
    // MARK: OptiTrack Flags
    var isOptiTrackOptIn: Bool?
    {
        get
        {
            return self.standardUserDefaults.value(forKey: UserDefaultsKeys.isOptiTrackOptIn.rawValue) as? Bool
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any,
                                  key: UserDefaultsKeys.isOptiTrackOptIn.rawValue)
        }
    }
    var lastPingTime: TimeInterval
    {
        get { return self.standardUserDefaults.double(forKey: UserDefaultsKeys.lastPingTime.rawValue)}
        set { self.setDefaultObject(forObject: newValue as Any,
                                    key: UserDefaultsKeys.lastPingTime.rawValue) }
    }
    
    var firstVisitTimestamp: Int
    {
        get { return self.standardUserDefaults.integer(forKey: UserDefaultsKeys.firstVisitTimestamp.rawValue)}
        set { self.setDefaultObject(forObject: newValue as Any,
                                    key: UserDefaultsKeys.firstVisitTimestamp.rawValue) }
    }
    var isSetUserIdSucceed : Bool
    {
        get { return  self.standardUserDefaults.bool(forKey: UserDefaultsKeys.isSetUserIdSucceed.rawValue)}
        
        set { self.setDefaultObject(forObject: newValue as Bool,
                                    key: UserDefaultsKeys.isSetUserIdSucceed.rawValue) }
    }
    // MARK: Real time flags
    var realtimeSetUserIdFailed: Bool
    {
        get
        {
            return self.standardUserDefaults.bool(forKey: UserDefaultsKeys.realtimeSetUserIdFailed.rawValue)
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any,
                                  key: UserDefaultsKeys.realtimeSetUserIdFailed.rawValue)
        }
    }
    var realtimeFailedOriginalVisitorId: String?
    {
        get
        {
            return self.standardUserDefaults.string(forKey: UserDefaultsKeys.realtimeFailedOriginalVisitorId.rawValue)
        }
        set
        {
            if newValue == nil {
                standardUserDefaults.removeObject(forKey: UserDefaultsKeys.realtimeFailedOriginalVisitorId.rawValue)
            } else {
                self.setDefaultObject(forObject: newValue as Any,
                                      key: UserDefaultsKeys.realtimeFailedOriginalVisitorId.rawValue)
            }
        }
    }
    var realtimeSetEmailFailed: Bool
    {
        get
        {
            return self.standardUserDefaults.bool(forKey: UserDefaultsKeys.realtimeSetEmailFailed.rawValue)
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any,
                                  key: UserDefaultsKeys.realtimeSetEmailFailed.rawValue)
        }
    }
    var realtimeFailedEmail: String?
    {
        get
        {
            return self.standardUserDefaults.string(forKey: UserDefaultsKeys.realtimeFailedEmail.rawValue)
        }
        set
        {
            if newValue == nil {
                standardUserDefaults.removeObject(forKey: UserDefaultsKeys.realtimeFailedEmail.rawValue)
            } else {
                self.setDefaultObject(forObject: newValue as Any,
                                      key: UserDefaultsKeys.realtimeFailedEmail.rawValue)
            }
        }
    }
}
