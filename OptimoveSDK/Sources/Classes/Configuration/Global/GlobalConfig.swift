//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

// MARK: - GlobalConfig

struct GlobalConfig: Codable, Equatable {
    let general: GlobalGeneralConfig
    let optitrack: GlobalOptitrackConfig
    let coreEvents: [String: EventsConfig]

    init(general: GlobalGeneralConfig,
         optitrack: GlobalOptitrackConfig,
         coreEvents: [String: EventsConfig])
    {
        self.general = general
        self.optitrack = optitrack
        self.coreEvents = coreEvents
    }

    enum CodingKeys: String, CodingKey {
        case general
        case optitrack
        case coreEvents = "core_events"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        general = try container.decode(GlobalGeneralConfig.self, forKey: .general)
        optitrack = try container.decode(GlobalOptitrackConfig.self, forKey: .optitrack)
        coreEvents = try container.decode([String: EventsConfig].self, forKey: .coreEvents)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(general, forKey: .general)
        try container.encode(optitrack, forKey: .optitrack)
        try container.encode(coreEvents, forKey: .coreEvents)
    }
}

// MARK: - General

struct GlobalGeneralConfig: Codable, Equatable {
    let logsServiceEndpoint: URL

    init(logsServiceEndpoint: URL) {
        self.logsServiceEndpoint = logsServiceEndpoint
    }

    enum CodingKeys: String, CodingKey {
        case logsServiceEndpoint = "logs_service_endpoint"
    }
}

// MARK: - Optitrack

struct GlobalOptitrackConfig: Codable, Equatable {
    let eventCategoryName: String

    init(eventCategoryName: String) {
        self.eventCategoryName = eventCategoryName
    }

    enum CodingKeys: String, CodingKey {
        case eventCategoryName = "event_category_name"
    }
}
