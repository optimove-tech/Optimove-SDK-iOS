//
//  Parser.swift
//  OptimoveSDK
//
//  Created by Mobile Developer Optimove on 05/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

struct Parser
{
    static func extractJSONFrom(data:Data?) -> (json:[String:Any]?,error:OptimoveError?)
    {
        if let data = data
        {
            let json:[String:Any]!
            do
            {
                json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
            }
            catch
            {
                return (nil, .canNotParseData)
            }
            return (json, nil)
        }
        return (nil,.emptyData)
    }
    
    static func parseOptitrackMetadata(from json:[String:Any]) -> OptitrackMetaData?
    {
        guard let optitrackConfig               = json[Keys.Configuration.optitrackMetaData.rawValue] as? [String: Any],
            let sendUserAgentHeader             = optitrackConfig[Keys.Configuration.sendUserAgentHeader.rawValue] as? Bool,
            let eventIdCustomDimensionId        = optitrackConfig[Keys.Configuration.eventIdCustomDimensionId.rawValue] as? Int,
            let eventNameCustomDimensionId      = optitrackConfig[Keys.Configuration.eventNameCustomDimensionId.rawValue] as? Int,
            let eventCategoryName               = optitrackConfig[Keys.Configuration.eventCategoryName.rawValue] as? String,
            let visitCustomDimensionsStartId    = optitrackConfig[Keys.Configuration.visitCustomDimensionsStartId.rawValue] as? Int,
            let maxVisitCustomDimensions        = optitrackConfig[Keys.Configuration.maxVisitCustomDimensions.rawValue] as? Int,
            let actionCustomDimensionsStartId   = optitrackConfig[Keys.Configuration.actionCustomDimensionsStartId.rawValue] as? Int,
            let maxActionCustomDimensions       = optitrackConfig[Keys.Configuration.maxActionCustomDimensions.rawValue] as? Int,
            let optitrackEndpoint               = optitrackConfig[Keys.Configuration.optitrackEndpoint.rawValue] as? String,
            let siteId                          = optitrackConfig[Keys.Configuration.siteId.rawValue] as? Int
            else
        {
                return nil
            }
                
        return OptitrackMetaData(sendUserAgentHeader: sendUserAgentHeader,
                                 eventIdCustomDimensionId: eventIdCustomDimensionId,
                                 eventNameCustomDimensionId: eventNameCustomDimensionId,
                                 eventCategoryName: eventCategoryName,
                                 visitCustomDimensionsStartId: visitCustomDimensionsStartId,
                                 maxVisitCustomDimensions: maxVisitCustomDimensions,
                                 actionCustomDimensionsStartId: actionCustomDimensionsStartId,
                                 maxActionCustomDimensions: maxActionCustomDimensions,
                                 optitrackEndpoint: optitrackEndpoint + NSLocalizedString("piwik.php", comment: ""),
                                 siteId: siteId)
    }
    
    static func parseFirebaseKeys(from json: [String:Any], isClientService:Bool = false) -> FirebaseMetaData?
    {
        guard let bundleId = Bundle.main.bundleIdentifier,
            let appIds = json[Keys.Configuration.appIds.rawValue] as? [String:Any],
            let ios = appIds[Keys.Configuration.ios.rawValue] as? [String:Any],
            let webApiKey = json[Keys.Configuration.webApiKey.rawValue] as? String,
            let appId = isClientService ? ios[Keys.Configuration.clientServiceAppNs.rawValue] as? String :  ios[bundleId] as? String,
            let dbUrl = json[Keys.Configuration.dbUrl.rawValue] as? String,
            let senderId = json[Keys.Configuration.senderId.rawValue] as? String,
            let storageBucket = json[Keys.Configuration.storageBucket.rawValue] as? String,
            let projectId = json[Keys.Configuration.projectId.rawValue] as? String
            else {
                return nil
        }
        
        return FirebaseMetaData(webApiKey: webApiKey,
                                appId: appId,
                                dbUrl: dbUrl,
                                senderId: senderId,
                                storageBucket: storageBucket,
                                projectId: projectId)
    }
    
    static func extractOptipushConfigurations(from json:[String:Any]) -> [String:Any]?
    {
        if let mobileConfig = json[Keys.Configuration.mobile.rawValue] as? [String: Any]
        {
            return mobileConfig
        }
        return nil
    }
    
    static func extractOptipushPermissions(from json:[String:Any]) -> Bool?
    {
        if let isPermitted = json[Keys.Configuration.enableOptipush.rawValue] as? Bool
        {
            return isPermitted
        }
        return nil
    }
    
    static func extractSiteIdFrom(json:[String:Any]) -> Int?
    {
        if let siteId = json[Keys.Configuration.tenantId.rawValue] as? Int
        {
            return siteId
        }
        return nil
    }
    
    static func extractOptimoveComponentsPermissions(from json:[String:Any]) -> (isOptipushEnabled: Bool,isOptitrackEnabled: Bool) //TODO: refactor
    {
        let isOptipushEnabled = json[Keys.Configuration.enableOptipush.rawValue] as? Bool ?? false
        let isOptitrackEnabled = json[Keys.Configuration.enableOptitrack.rawValue] as? Bool ?? false
        return (isOptipushEnabled,isOptitrackEnabled)
    }
    
    static func parseOptipushMetaData(from json:[String:Any]) -> OptipushMetaData?
    {
        guard let optipushRegistrationEndpoint                          = json[Keys.Configuration.registrationServiceRegistrationEndPoint.rawValue] as? String,
            let   optipushGeneralEndPoint                               = json[Keys.Configuration.registrationServiceOtherEndPoint.rawValue] as? String
            
            else {return nil}
        
        return OptipushMetaData(registrationServiceRegistrationEndPoint: optipushRegistrationEndpoint,
                                registrationServiceOtherEndPoint: optipushGeneralEndPoint)
        
    }
}
