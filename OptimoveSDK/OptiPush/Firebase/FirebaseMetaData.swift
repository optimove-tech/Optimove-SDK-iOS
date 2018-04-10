//
//  FirebaseMetaData.swift
//  OptimoveSDK
//
//  Created by Mobile Developer Optimove on 28/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

struct FirebaseMetaData
{
    var webApiKey       : String?
    var appId           : String?
    var dbUrl           : String?
    var senderId        : String?
    var storageBucket   : String?
    var projectId       : String?
}


extension FirebaseMetaData
{
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
}
