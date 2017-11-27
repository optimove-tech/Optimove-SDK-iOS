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
    static func getLegitJSON(data:Data?, response:URLResponse?, error:Error?) -> (json:[String:Any]?, error:Error?)
    {
        guard (error == nil) else
        {
            print("There was an error with your request: \(String(describing: error))")
            return (nil,error)
        }
        
        guard let data = data else
        {
            print("No data was returned by the request!")
            return (nil,nil)
        }
        let json:[String:Any]!
        do
        {
            json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
        }
        catch
        {
            print("Could not parse the data as JSON: '\(data)'")
            return (nil,nil)
        }
        return(json,nil)
    }
    
    static func parseOptitrackMetadata(from json:[String:Any]) -> OptitrackMetaData?
    {
        guard let sendUserAgentHeader           = json[Keys.Configuration.sendUserAgentHeader.rawValue] as? Bool,
            let eventIdCustomDimensionId        = json[Keys.Configuration.eventIdCustomDimensionId.rawValue] as? Int,
            let eventNameCustomDimensionId      = json[Keys.Configuration.eventNameCustomDimensionId.rawValue] as? Int,
            let eventCategoryName               = json[Keys.Configuration.eventCategoryName.rawValue] as? String,
            let visitCustomDimensionsStartId    = json[Keys.Configuration.visitCustomDimensionsStartId.rawValue] as? Int,
            let maxVisitCustomDimensions        = json[Keys.Configuration.maxVisitCustomDimensions.rawValue] as? Int,
            let actionCustomDimensionsStartId   = json[Keys.Configuration.actionCustomDimensionsStartId.rawValue] as? Int,
            let maxActionCustomDimensions       = json[Keys.Configuration.maxActionCustomDimensions.rawValue] as? Int,
            let optitrackEndpoint               = json[Keys.Configuration.optitrackEndpoint.rawValue] as? String,
            let siteId                          = json[Keys.Configuration.siteId.rawValue] as? Int
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
                                 optitrackEndpoint: optitrackEndpoint + "piwik.php",
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
    
    
    
    static func parseOptipushMetaData(from json:[String:Any]) -> OptipushMetaData?
    {
        guard let optipushRegistrationEndpoint                          = json[Keys.Configuration.registrationServiceRegistrationEndPoint.rawValue] as? String,
            let   optipushGeneralEndPoint                               = json[Keys.Configuration.registrationServiceOtherEndPoint.rawValue] as? String
            
            else {return nil}
        
        return OptipushMetaData(registrationServiceRegistrationEndPoint: optipushRegistrationEndpoint,
                                registrationServiceOtherEndPoint: optipushGeneralEndPoint)
        
    }
}
