//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

// MARK: - GlobalConfig

public struct GlobalConfig: Codable, Equatable {
    public let general: GlobalGeneralConfig
    public let optitrack: GlobalOptitrackConfig
    public let coreEvents: [String: EventsConfig]

    public init(general: GlobalGeneralConfig,
         optitrack: GlobalOptitrackConfig,
         coreEvents: [String: EventsConfig]) {
        self.general = general
        self.optitrack = optitrack
        self.coreEvents = coreEvents
    }

    enum CodingKeys: String, CodingKey {
        case general = "general"
        case optitrack = "optitrack"
        case coreEvents = "core_events"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        general = try container.decode(GlobalGeneralConfig.self, forKey: .general)
        optitrack = try container.decode(GlobalOptitrackConfig.self, forKey: .optitrack)
        coreEvents = try container.decode([String: EventsConfig].self, forKey: .coreEvents)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(general, forKey: .general)
        try container.encode(optitrack, forKey: .optitrack)
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


// MARK: - Optitrack
public struct GlobalOptitrackConfig: Codable, Equatable {
    public let eventCategoryName: String

    public init(eventCategoryName: String) {
        self.eventCategoryName = eventCategoryName
    }

    enum CodingKeys: String, CodingKey {
        case eventCategoryName = "event_category_name"
    }
}
