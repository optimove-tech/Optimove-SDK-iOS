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
