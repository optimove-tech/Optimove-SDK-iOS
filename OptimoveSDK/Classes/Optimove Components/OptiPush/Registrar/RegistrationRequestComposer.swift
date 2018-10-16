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
            let iOSToken = [OptimoveKeys.Registration.bundleID.rawValue : bundleID,
                            OptimoveKeys.Registration.deviceID.rawValue : DeviceID ]
            requestJsonData[OptimoveKeys.Registration.iOSToken.rawValue]    = iOSToken
            requestJsonData[OptimoveKeys.Registration.tenantID.rawValue]    = TenantID
            if let customerId = OptimoveUserDefaults.shared.customerID {
                requestJsonData[OptimoveKeys.Registration.customerID.rawValue] = customerId
            } else {
                requestJsonData[OptimoveKeys.Registration.visitorID.rawValue]   = VisitorID
            }
            let dictionary = state == .optIn ? [OptimoveKeys.Registration.optIn.rawValue : requestJsonData] : [OptimoveKeys.Registration.optOut.rawValue: requestJsonData]
            
            return try! JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
        }
        return nil
    }
    
    func buildRegisterRequest() -> Data?
    {
        guard let bundleID = Bundle.main.bundleIdentifier?.replacingOccurrences(of: ".", with: "_")  else { return nil }
        var requestJsonData = [String: Any]()
        var bundle = [String:Any]()
        bundle[OptimoveKeys.Registration.optIn.rawValue] = OptimoveUserDefaults.shared.isMbaasOptIn
        bundle[OptimoveKeys.Registration.token.rawValue] = OptimoveUserDefaults.shared.fcmToken
        let app = [bundleID: bundle]
        var device: [String: Any] = [OptimoveKeys.Registration.apps.rawValue: app]
        device[OptimoveKeys.Registration.osVersion.rawValue] = OSVersion
        let ios = [DeviceID: device]
        requestJsonData[OptimoveKeys.Registration.iOSToken.rawValue]         = ios
        requestJsonData[OptimoveKeys.Registration.tenantID.rawValue]         = OptimoveUserDefaults.shared.siteID
       
        if let customerId = OptimoveUserDefaults.shared.customerID {
            requestJsonData[OptimoveKeys.Registration.origVisitorID.rawValue]    = OptimoveUserDefaults.shared.visitorID
            requestJsonData[OptimoveKeys.Registration.isConversion.rawValue]    = OptimoveUserDefaults.shared.isFirstConversion
            requestJsonData[OptimoveKeys.Registration.customerID.rawValue]       = customerId
        } else {
            requestJsonData[OptimoveKeys.Registration.visitorID.rawValue]        = OptimoveUserDefaults.shared.visitorID
        }
        let dictionary = [OptimoveKeys.Registration.registrationData.rawValue : requestJsonData]
        
        return try! JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
    }
    
    func buildUnregisterRequest() -> Data?
    {
        guard let bundleID = Bundle.main.bundleIdentifier?.replacingOccurrences(of: ".", with: "_")  else {return nil}
         var requestJsonData = [String: Any]()
        let iOSToken = [OptimoveKeys.Registration.bundleID.rawValue : bundleID,
                        OptimoveKeys.Registration.deviceID.rawValue : DeviceID ]
        
        requestJsonData[OptimoveKeys.Registration.iOSToken.rawValue]     = iOSToken
        requestJsonData[OptimoveKeys.Registration.tenantID.rawValue]     = TenantID
        
        if let customerId = OptimoveUserDefaults.shared.customerID {
            requestJsonData[OptimoveKeys.Registration.customerID.rawValue] = customerId
        } else {
            requestJsonData[OptimoveKeys.Registration.visitorID.rawValue]    = VisitorID
        }
        let dictionary = [OptimoveKeys.Registration.unregistrationData.rawValue : requestJsonData]
        
        return try! JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
    }
}
