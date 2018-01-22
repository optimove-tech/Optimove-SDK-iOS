//
//  UserInSession.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 11/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

class UserInSession: Synchronizable
{
    let lock:NSLock
    enum UserDefaultsKeys: String
    {
        case configurationEndPoint  = "configurationEndPoint"
        case isOptIn                = "isOptIn"
        case isFirstConversion      = "isFirstConversion"
        case tenantToken            = "tenantToken"
        case siteID                 = "siteID"
        case version                = "version"
        case customerID             = "customerID"
        case visitorID              = "visitorID"
        case deviceToken            = "deviceToken"
        case fcmToken               = "fcmToken"
        case isFirstLaunch          = "isFirstLaunch"
        case hasOptInOutJsonFile    = "hasOptInOutJsonFile"
        case hasRegisterJsonFile    = "hasRegisterJsonFile"
        case hasUnregisterJsonFile  = "hasUnregisterJsonFile"
        case userAgentHeader        = "userAgentHeader"
        case registrationSuccess    = "registrationSuccess"
        case optSuccess             = "optSuccess"
        case isSetUserIdSucceed     = "isSetUserIdSucceed"
        case userHasFirebase        = "userHasFirebase"
        case apnsToken               = "apnsToken"
        case backupNotificationEvents = "backupNotificationEvents"
    }
    
    static let shared = UserInSession()
    private init()
    {
        lock = NSLock()
    }
    
    var backupNotificationEvents: [String]
    {
        get
        {
            return  UserDefaults.standard.value(forKey: UserDefaultsKeys.backupNotificationEvents.rawValue) as? [String] ?? []
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any, key: UserDefaultsKeys.backupNotificationEvents.rawValue)
        }
    }
    
    var configurationEndPoint: String
    {
        get
        {
            if let id = UserDefaults.standard.string(forKey: UserDefaultsKeys.configurationEndPoint.rawValue)
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
    
    var isOptIn: Bool?
    {
        get
        {
            lock.lock()
            let val = UserDefaults.standard.value(forKey: UserDefaultsKeys.isOptIn.rawValue) as? Bool
            lock.unlock()
            return val
        }
        set
        {
            lock.lock()
            self.setDefaultObject(forObject: newValue as Any,
                                                  key: UserDefaultsKeys.isOptIn.rawValue)
            lock.unlock()
        }
    }
    var siteID:Int?
    {
        get
        {
            if let id = UserDefaults.standard.value(forKey: UserDefaultsKeys.siteID.rawValue) as? Int
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
            if let id = UserDefaults.standard.string(forKey: UserDefaultsKeys.tenantToken.rawValue)
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
            if let id = UserDefaults.standard.string(forKey: UserDefaultsKeys.version.rawValue)
            {
                return id
            }
            return nil
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any, key: UserDefaultsKeys.version.rawValue)
        }
    }
    
    var userHasFirebase : Bool
    {
        get { return UserDefaults.standard.bool(forKey: UserDefaultsKeys.userHasFirebase.rawValue)}
        set { self.setDefaultObject(forObject: newValue as Any,
                                                  key: UserDefaultsKeys.userHasFirebase.rawValue) }
    }
    
    var customerID:String?
    {
        get
        {
            if let id = UserDefaults.standard.string(forKey: UserDefaultsKeys.customerID.rawValue)
            {
                return id
            }
            return nil
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any, key: UserDefaultsKeys.customerID.rawValue)
        }
    }
    var visitorID:String?
    {
        get
        {
            if let id = UserDefaults.standard.string(forKey: UserDefaultsKeys.visitorID.rawValue)
            {
                return id
            }
            return nil
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any, key: UserDefaultsKeys.visitorID.rawValue)
        }
    }
    
    var fcmToken: String?
    {
        get
        {
            if let id = UserDefaults.standard.string(forKey: UserDefaultsKeys.fcmToken.rawValue)
            {
                return id
            }
            return nil
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any, key: UserDefaultsKeys.fcmToken.rawValue)
        }
    }
    
    var isFirstConversion : Bool?
    {
        get { return UserDefaults.standard.value(forKey: UserDefaultsKeys.isFirstConversion.rawValue) as? Bool }
        set { self.setDefaultObject(forObject: newValue as Any,
                                                  key: UserDefaultsKeys.isFirstConversion.rawValue) }
    }
    
    var apnsToken: Data?
    {
        get
        {
            return UserDefaults.standard.data(forKey: UserDefaultsKeys.apnsToken.rawValue)
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any, key: UserDefaultsKeys.apnsToken.rawValue)
        }
    }
    
    var isSetUserIdSucceed : Bool
    {
        get { return  UserDefaults.standard.bool(forKey: UserDefaultsKeys.isSetUserIdSucceed.rawValue)}
        
        set { self.setDefaultObject(forObject: newValue as Bool,
                                                  key: UserDefaultsKeys.isSetUserIdSucceed.rawValue) }
    }
    
    var isFirstLaunch : Bool
    {
        get
        {
            return UserDefaults.standard.bool(forKey: UserDefaultsKeys.isFirstLaunch.rawValue)
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any,
                                                  key: UserDefaultsKeys.isFirstLaunch.rawValue)
        }
    }
    
    var hasOptInOutJsonFile : Bool
    {
        get
        {
            return UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasOptInOutJsonFile.rawValue)
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any,
                                                key: UserDefaultsKeys.hasOptInOutJsonFile.rawValue)
        }
    }
    
    var hasRegisterJsonFile : Bool?
    {
        get
        {
            return UserDefaults.standard.value(forKey: UserDefaultsKeys.hasRegisterJsonFile.rawValue) as? Bool
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any,
                                                key: UserDefaultsKeys.hasRegisterJsonFile.rawValue)
        }
    }
    var hasUnregisterJsonFile : Bool
    {
        get
        {
            return UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasUnregisterJsonFile.rawValue)
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any,
                                                key: UserDefaultsKeys.hasUnregisterJsonFile.rawValue)
        }
    }
    var isRegistrationSuccess : Bool
    {
        get
        {
            return UserDefaults.standard.bool(forKey: UserDefaultsKeys.registrationSuccess.rawValue)
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
            return UserDefaults.standard.bool(forKey: UserDefaultsKeys.optSuccess.rawValue)
        }
        set
        {
            self.setDefaultObject(forObject: newValue as Any,
                                                key: UserDefaultsKeys.optSuccess.rawValue)
        }
    }

}
