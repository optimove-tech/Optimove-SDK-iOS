//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

// MARK: - GlobalConfig

public struct GlobalConfig: Codable, Equatable {
    public let general: GlobalGeneralConfig
    public let optitrack: GlobalOptitrackConfig
    public let optipush: GlobalOptipushConfig
    public let coreEvents: [String: EventsConfig]

    public init(general: GlobalGeneralConfig,
         optitrack: GlobalOptitrackConfig,
         optipush: GlobalOptipushConfig,
         coreEvents: [String: EventsConfig]) {
        self.general = general
        self.optitrack = optitrack
        self.optipush = optipush
        self.coreEvents = coreEvents
    }

    enum CodingKeys: String, CodingKey {
        case general = "general"
        case optitrack = "optitrack"
        case optipush = "optipush"
        case coreEvents = "core_events"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        general = try container.decode(GlobalGeneralConfig.self, forKey: .general)
        optitrack = try container.decode(GlobalOptitrackConfig.self, forKey: .optitrack)
        optipush = try container.decode(GlobalOptipushConfig.self, forKey: .optipush)
        coreEvents = try container.decode([String: EventsConfig].self, forKey: .coreEvents)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(general, forKey: .general)
        try container.encode(optitrack, forKey: .optitrack)
        try container.encode(optipush, forKey: .optipush)
        try container.encode(coreEvents, forKey: .coreEvents)
    }
}

// MARK: - General
public struct GlobalGeneralConfig: Codable, Equatable {
    public let logsServiceEndpoint: URL

    public init(logsServiceEndpoint: URL) {
        self.logsServiceEndpoint = logsServiceEndpoint
    }

    enum CodingKeys: String, CodingKey {
        case logsServiceEndpoint = "logs_service_endpoint"
    }
}

// MARK: - Optipush
public struct GlobalOptipushConfig: Codable, Equatable {
    public let mbaasEndpoint: URL

    public init(mbaasEndpoint: URL) {
        self.mbaasEndpoint = mbaasEndpoint
    }

    enum CodingKeys: String, CodingKey {
        case mbaasEndpoint = "mbaas_endpoint"
    }
}

// MARK: - Optitrack
public struct GlobalOptitrackConfig: Codable, Equatable {
    public let eventCategoryName: String
    public let customDimensionIDs: CustomDimensionIDs

    public init(eventCategoryName: String, customDimensionIDs: CustomDimensionIDs) {
        self.eventCategoryName = eventCategoryName
        self.customDimensionIDs = customDimensionIDs
    }

    enum CodingKeys: String, CodingKey {
        case eventCategoryName = "event_category_name"
        case customDimensionIDs = "custom_dimension_ids"
    }
}

// MARK: - CustomDimensionIDS
public struct CustomDimensionIDs: Codable, Equatable {
    public let eventIDCustomDimensionID: Int
    public let eventNameCustomDimensionID: Int
    public let visitCustomDimensionsStartID: Int
    public let maxVisitCustomDimensions: Int
    public let actionCustomDimensionsStartID: Int
    public let maxActionCustomDimensions: Int

    public init(
        eventIDCustomDimensionID: Int,
        eventNameCustomDimensionID: Int,
        visitCustomDimensionsStartID: Int,
        maxVisitCustomDimensions: Int,
        actionCustomDimensionsStartID: Int,
        maxActionCustomDimensions: Int) {
        self.eventIDCustomDimensionID = eventIDCustomDimensionID
        self.eventNameCustomDimensionID = eventNameCustomDimensionID
        self.visitCustomDimensionsStartID = visitCustomDimensionsStartID
        self.maxVisitCustomDimensions = maxVisitCustomDimensions
        self.actionCustomDimensionsStartID = actionCustomDimensionsStartID
        self.maxActionCustomDimensions = maxActionCustomDimensions
    }

    enum CodingKeys: String, CodingKey {
        case eventIDCustomDimensionID = "event_id_custom_dimension_id"
        case eventNameCustomDimensionID = "event_name_custom_dimension_id"
        case visitCustomDimensionsStartID = "visit_custom_dimensions_start_id"
        case maxVisitCustomDimensions = "max_visit_custom_dimensions"
        case actionCustomDimensionsStartID = "action_custom_dimensions_start_id"
        case maxActionCustomDimensions = "max_action_custom_dimensions"
    }
}
