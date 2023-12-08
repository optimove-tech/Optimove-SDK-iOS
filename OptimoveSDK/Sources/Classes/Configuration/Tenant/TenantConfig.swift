//  Copyright © 2017 Optimove. All rights reserved.

struct TenantConfig: Codable, Equatable {
    let isSupportedAirship: Bool
    let isEnableRealtime: Bool
    let isEnableRealtimeThroughOptistream: Bool
    let isProductionLogsEnabled: Bool
    let realtime: TenantRealtimeConfig
    var optitrack: TenantOptitrackConfig
    let events: [String: EventsConfig]

    init(
        realtime: TenantRealtimeConfig,
        optitrack: TenantOptitrackConfig,
        events: [String: EventsConfig],
        isEnableRealtime: Bool,
        isSupportedAirship: Bool,
        isEnableRealtimeThroughOptistream: Bool,
        isProductionLogsEnabled: Bool
    ) {
        self.realtime = realtime
        self.optitrack = optitrack
        self.events = events
        self.isEnableRealtime = isEnableRealtime
        self.isSupportedAirship = isSupportedAirship
        self.isEnableRealtimeThroughOptistream = isEnableRealtimeThroughOptistream
        self.isProductionLogsEnabled = isProductionLogsEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isSupportedAirship = try container.decodeIfPresent(Bool.self, forKey: .supportAirship) ?? false
        isEnableRealtime = try container.decode(Bool.self, forKey: .enableRealtime)
        isProductionLogsEnabled = try container.decodeIfPresent(Bool.self, forKey: .prodLogsEnabled) ?? false
        isEnableRealtimeThroughOptistream = try container.decodeIfPresent(Bool.self, forKey: .enableRealtimeThroughOptistream) ?? false
        realtime = try container.decode(TenantRealtimeConfig.self, forKey: .realtime)
        optitrack = try container.decode(TenantOptitrackConfig.self, forKey: .optitrack)
        events = try container.decode([String: EventsConfig].self, forKey: .events)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(isSupportedAirship, forKey: .supportAirship)
        try container.encodeIfPresent(isProductionLogsEnabled, forKey: .prodLogsEnabled)
        try container.encode(isEnableRealtime, forKey: .enableRealtime)
        try container.encodeIfPresent(isEnableRealtimeThroughOptistream, forKey: .enableRealtimeThroughOptistream)
        try container.encode(realtime, forKey: .realtime)
        try container.encode(optitrack, forKey: .optitrack)
        try container.encode(events, forKey: .events)
    }

    enum CodingKeys: String, CodingKey {
        case supportAirship
        case enableRealtime
        case enableRealtimeThroughOptistream
        case prodLogsEnabled
        case realtime = "realtimeMetaData"
        case optitrack = "optitrackMetaData"
        case mobile
        case events
        case siteId
    }
}
