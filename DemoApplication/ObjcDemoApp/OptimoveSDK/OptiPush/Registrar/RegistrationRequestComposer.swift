//
//  JSONComposer.swift
//  OptimoveSDK
//
//  Created by Mobile Developer Optimove on 26/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation
import os.log

struct RegistrationRequestComposer
{
    static func composeOptInOutVisitorJSON(forState state: State.Opt) -> Data?
    {
        guard let tenantId = TenantID else {return nil}
        var requestJsonData = [String: Any]()
        if let bundleID = Bundle.main.bundleIdentifier?.replacingOccurrences(of: ".", with: "_")  {
            
            let iOSToken = [Keys.Registration.bundleID.rawValue : bundleID,
                            Keys.Registration.deviceID.rawValue : DeviceID ]
            requestJsonData[Keys.Registration.iOSToken.rawValue]    = iOSToken
            requestJsonData[Keys.Registration.visitorID.rawValue]   = VisitorID
            requestJsonData[Keys.Registration.tenantID.rawValue]    = tenantId
            
            switch state
            {
            case .optIn:
                Optimove.sharedInstance.logger.debug("Visitor opt in")
                requestJsonData = [Keys.Registration.optIn.rawValue : requestJsonData]
            case .optOut:
                
                Optimove.sharedInstance.logger.debug("Visitor opt out")
                requestJsonData = [Keys.Registration.optOut.rawValue: requestJsonData]
            }
            
            
            return try! JSONSerialization.data(withJSONObject: requestJsonData, options: .prettyPrinted)
        }
        return nil
    }
    
    static func composeOptInOutCustomerJSON(forState state: State.Opt) -> Data?
    {
        var requestJsonData = [String: Any]()
        guard let tenantId = TenantID else {return nil}
        if let bundleID = Bundle.main.bundleIdentifier?.replacingOccurrences(of: ".", with: "_")  {
            let iOSToken = [Keys.Registration.bundleID.rawValue : bundleID,
                            Keys.Registration.deviceID.rawValue : DeviceID ]
            
            requestJsonData[Keys.Registration.iOSToken.rawValue]     = iOSToken
            requestJsonData[Keys.Registration.customerID.rawValue]   = UserInSession.shared.customerID
            requestJsonData[Keys.Registration.tenantID.rawValue]     = tenantId
            
            let dictionary = state == .optIn ? [Keys.Registration.optIn.rawValue : requestJsonData] : [Keys.Registration.optOut.rawValue: requestJsonData]
            
            return try! JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
        }
        return nil
    }
    
    
    static func composeRegisterCustomer() -> Data?
    {
        var requestJsonData = [String: Any]()
        var bundle = [String:Any]()
        
        bundle[Keys.Registration.optIn.rawValue] = UserInSession.shared.isOptIn ?? true
        bundle[Keys.Registration.token.rawValue] = UserInSession.shared.fcmToken
        
        guard let bundleID = Bundle.main.bundleIdentifier?.replacingOccurrences(of: ".", with: "_")  else { return nil }
        let app = [bundleID: bundle]
        var device: [String: Any] = [Keys.Registration.apps.rawValue: app]
        device[Keys.Registration.osVersion.rawValue] = OSVersion
        let ios = [DeviceID: device]
        
        guard let tenantId = TenantID else {return nil}
        
        requestJsonData[Keys.Registration.iOSToken.rawValue]         = ios
        requestJsonData[Keys.Registration.origVisitorID.rawValue]    = UserInSession.shared.visitorID
        requestJsonData[Keys.Registration.isCopnversion.rawValue]    = UserInSession.shared.isFirstConversion
        requestJsonData[Keys.Registration.customerID.rawValue]       = UserInSession.shared.customerID
        requestJsonData[Keys.Registration.tenantID.rawValue]         = tenantId
        
        let dictionary = [Keys.Registration.registrationData.rawValue : requestJsonData]
        
        return try! JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
    }
    
    static func composeRegisterVisitor() -> Data?
    {
        var requestJsonData = [String: Any]()
        var bundle = [String:Any]()

        bundle[Keys.Registration.optIn.rawValue] = UserInSession.shared.isOptIn ?? true
        bundle[Keys.Registration.token.rawValue] = UserInSession.shared.fcmToken
        
        guard let bundleID = Bundle.main.bundleIdentifier?.replacingOccurrences(of: ".", with: "_") else { return nil }
        let app = [bundleID: bundle]
        var device: [String: Any] = [Keys.Registration.apps.rawValue: app]
        device[Keys.Registration.osVersion.rawValue] = OSVersion
        let ios = [DeviceID: device]
        
        guard let tenantId = TenantID else {return nil}
        requestJsonData[Keys.Registration.iOSToken.rawValue]         = ios
        requestJsonData[Keys.Registration.visitorID.rawValue]        = UserInSession.shared.visitorID
        requestJsonData[Keys.Registration.tenantID.rawValue]         = tenantId
        
        let dictionary = [Keys.Registration.registrationData.rawValue : requestJsonData]
        
        return try! JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
    }
    
    static func composeUnregisterCustomerJSON() -> Data?
    {
        var requestJsonData = [String: Any]()
        guard let tenantId = TenantID else {return nil}
        if let bundleID = Bundle.main.bundleIdentifier?.replacingOccurrences(of: ".", with: "_")
        {
            let iOSToken = [Keys.Registration.bundleID.rawValue : bundleID,
                            Keys.Registration.deviceID.rawValue : DeviceID ]
            
            requestJsonData[Keys.Registration.iOSToken.rawValue]     = iOSToken
            requestJsonData[Keys.Registration.customerID.rawValue]   = UserInSession.shared.customerID
            requestJsonData[Keys.Registration.tenantID.rawValue]     = tenantId
            
            let dictionary = [Keys.Registration.unregistrationData.rawValue : requestJsonData]
            
            return try! JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
        }
        return nil
    }
    
    static func composeUnregisterVisitor() -> Data?
    {
        var requestJsonData = [String: Any]()
        
        guard let bundleID = Bundle.main.bundleIdentifier?.replacingOccurrences(of: ".", with: "_")  else {return nil}
        guard let tenantId = TenantID else {return nil}
        let token = [Keys.Registration.bundleID.rawValue: bundleID,
                     Keys.Registration.deviceID.rawValue: DeviceID]
        
        requestJsonData[Keys.Registration.iOSToken.rawValue]     = token
        requestJsonData[Keys.Registration.visitorID.rawValue]    = VisitorID
        requestJsonData[Keys.Registration.tenantID.rawValue]     = tenantId
        
        let dictionary = [Keys.Registration.unregistrationData.rawValue : requestJsonData]
        
        return try! JSONSerialization.data(withJSONObject: dictionary,
                                               options: .prettyPrinted)
    }
}
