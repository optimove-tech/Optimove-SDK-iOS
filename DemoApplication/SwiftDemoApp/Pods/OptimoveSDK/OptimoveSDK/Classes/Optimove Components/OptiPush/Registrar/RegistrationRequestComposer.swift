//
//  JSONComposer.swift
//  OptimoveSDK
//
//  Created by Mobile Developer Optimove on 26/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

struct RegistrationRequestBuilder
{
    func buildOptRequest(state: State.Opt) -> Data?
    {
        var requestJsonData = [String: Any]()
        if let bundleID = Bundle.main.bundleIdentifier?.replacingOccurrences(of: ".", with: "_")  {
            let iOSToken = [Keys.Registration.bundleID.rawValue : bundleID,
                            Keys.Registration.deviceID.rawValue : DeviceID ]
            requestJsonData[Keys.Registration.iOSToken.rawValue]    = iOSToken
            requestJsonData[Keys.Registration.tenantID.rawValue]    = TenantID
            if let customerId = OptimoveUserDefaults.shared.customerID {
                requestJsonData[Keys.Registration.customerID.rawValue] = customerId
            } else {
                requestJsonData[Keys.Registration.visitorID.rawValue]   = VisitorID
            }
            let dictionary = state == .optIn ? [Keys.Registration.optIn.rawValue : requestJsonData] : [Keys.Registration.optOut.rawValue: requestJsonData]
            
            return try! JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
        }
        return nil
    }
    
    func buildRegisterRequest() -> Data?
    {
        guard let bundleID = Bundle.main.bundleIdentifier?.replacingOccurrences(of: ".", with: "_")  else { return nil }
        var requestJsonData = [String: Any]()
        var bundle = [String:Any]()
        bundle[Keys.Registration.optIn.rawValue] = OptimoveUserDefaults.shared.isMbaasOptIn
        bundle[Keys.Registration.token.rawValue] = OptimoveUserDefaults.shared.fcmToken
        let app = [bundleID: bundle]
        var device: [String: Any] = [Keys.Registration.apps.rawValue: app]
        device[Keys.Registration.osVersion.rawValue] = OSVersion
        let ios = [DeviceID: device]
        requestJsonData[Keys.Registration.iOSToken.rawValue]         = ios
        requestJsonData[Keys.Registration.tenantID.rawValue]         = OptimoveUserDefaults.shared.siteID
       
        if let customerId = OptimoveUserDefaults.shared.customerID {
            requestJsonData[Keys.Registration.origVisitorID.rawValue]    = OptimoveUserDefaults.shared.visitorID
            requestJsonData[Keys.Registration.isConversion.rawValue]    = OptimoveUserDefaults.shared.isFirstConversion
            requestJsonData[Keys.Registration.customerID.rawValue]       = customerId
        } else {
            requestJsonData[Keys.Registration.visitorID.rawValue]        = OptimoveUserDefaults.shared.visitorID
        }
        let dictionary = [Keys.Registration.registrationData.rawValue : requestJsonData]
        
        return try! JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
    }
    
    func buildUnregisterRequest() -> Data?
    {
        guard let bundleID = Bundle.main.bundleIdentifier?.replacingOccurrences(of: ".", with: "_")  else {return nil}
         var requestJsonData = [String: Any]()
        let iOSToken = [Keys.Registration.bundleID.rawValue : bundleID,
                        Keys.Registration.deviceID.rawValue : DeviceID ]
        
        requestJsonData[Keys.Registration.iOSToken.rawValue]     = iOSToken
        requestJsonData[Keys.Registration.tenantID.rawValue]     = TenantID
        
        if let customerId = OptimoveUserDefaults.shared.customerID {
            requestJsonData[Keys.Registration.customerID.rawValue] = customerId
        } else {
            requestJsonData[Keys.Registration.visitorID.rawValue]    = VisitorID
        }
        let dictionary = [Keys.Registration.unregistrationData.rawValue : requestJsonData]
        
        return try! JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
    }
}
