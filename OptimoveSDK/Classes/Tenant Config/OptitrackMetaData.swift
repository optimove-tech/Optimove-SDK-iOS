//
//  OptitrackMetaData.swift
//  OptimoveSDK
//
//  Created by Mobile Developer Optimove on 05/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

struct OptitrackMetaData: Codable, MetaData {
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
    var optitrackEndpoint: URL
    var siteId: Int
    var enableAdvertisingIdReport: Bool?
}
