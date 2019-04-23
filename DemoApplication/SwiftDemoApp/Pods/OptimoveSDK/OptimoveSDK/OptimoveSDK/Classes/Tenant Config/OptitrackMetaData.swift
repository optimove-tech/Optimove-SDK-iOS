//
//  OptitrackMetaData.swift
//  OptimoveSDK
//
//  Created by Mobile Developer Optimove on 05/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

struct OptitrackMetaData: Decodable {
    var sendUserAgentHeader: Bool
    var enableHeartBeatTimer: Bool
    var heartBeatTimer: Int
    var eventCategoryName: String
    var eventIdCustomDimensionId: Int
    var eventNameCustomDimensionId: Int
    var visitCustomDimensionsStartId: Int
    var maxVisitCustomDimensions: Int
    var actionCustomDimensionsStartId: Int
    var maxActionCustomDimensions: Int
    var optitrackEndpoint: String
    var siteId: Int
    var enableAdvertisingIdReport: Bool?

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.sendUserAgentHeader = try values.decode(Bool.self, forKey: .sendUserAgentHeader)
        self.enableHeartBeatTimer = try values.decode(Bool.self, forKey: .enableHeartBeatTimer)
        self.heartBeatTimer         = try values.decode(Int.self, forKey: .heartBeatTimer)
        self.eventCategoryName = try values.decode(String.self, forKey: .eventCategoryName)
        self.eventIdCustomDimensionId = try values.decode(Int.self, forKey: .eventIdCustomDimensionId)
        self.eventNameCustomDimensionId = try values.decode(Int.self, forKey: .eventNameCustomDimensionId)
        self.visitCustomDimensionsStartId = try values.decode(Int.self, forKey: .visitCustomDimensionsStartId)
        self.maxVisitCustomDimensions   = try values.decode(Int.self, forKey: .maxVisitCustomDimensions)
        self.actionCustomDimensionsStartId = try values.decode(Int.self, forKey: .actionCustomDimensionsStartId)
        self.maxActionCustomDimensions = try values.decode(Int.self, forKey: .maxActionCustomDimensions)
        let trackPath = try values.decode(String.self, forKey: .optitrackEndpoint)
        self.siteId = try values.decode(Int.self, forKey: .siteId)
        if trackPath.contains("/piwik.php") {
            self.optitrackEndpoint = trackPath
        } else {
            self.optitrackEndpoint = (trackPath.last! == "/") ? "\(trackPath)piwik.php" : "\(trackPath)/piwik.php"
        }
    }

    enum CodingKeys: String, CodingKey {
        case sendUserAgentHeader
        case enableHeartBeatTimer
        case heartBeatTimer
        case eventCategoryName
        case eventIdCustomDimensionId
        case eventNameCustomDimensionId
        case visitCustomDimensionsStartId
        case maxVisitCustomDimensions
        case actionCustomDimensionsStartId
        case maxActionCustomDimensions
        case optitrackEndpoint
        case siteId
        case enableAdvertisingIdReport

    }
}
