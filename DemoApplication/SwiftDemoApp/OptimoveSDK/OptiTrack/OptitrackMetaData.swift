//
//  OptitrackMetaData.swift
//  OptimoveSDK
//
//  Created by Mobile Developer Optimove on 05/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

struct OptitrackMetaData
{
    var sendUserAgentHeader             : Bool
    var eventIdCustomDimensionId        : Int
    var eventNameCustomDimensionId      : Int
    var eventCategoryName               : String
    var visitCustomDimensionsStartId    : Int
    var maxVisitCustomDimensions        : Int
    var actionCustomDimensionsStartId   : Int
    var maxActionCustomDimensions       : Int
    var optitrackEndpoint               : String
    var siteId                          : Int
}

extension OptitrackMetaData
{
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
}
