//  Copyright © 2017 Optimove. All rights reserved.

public struct TenantConfig: Codable, Equatable {
    public let isEnableRealtime: Bool
    public let isEnableRealtimeThroughOptistream: Bool
    public let isProductionLogsEnabled: Bool
    public let realtime: TenantRealtimeConfig
    public var optitrack: TenantOptitrackConfig
    public let events: [String: EventsConfig]

    public init(
        realtime: TenantRealtimeConfig,
        optitrack: TenantOptitrackConfig,
        events: [String: EventsConfig],
        isEnableRealtime: Bool,
        isEnableRealtimeThroughOptistream: Bool,
        isProductionLogsEnabled: Bool
    ) {
        self.realtime = realtime
        self.optitrack = optitrack
        self.events = events
        self.isEnableRealtime = isEnableRealtime
        self.isEnableRealtimeThroughOptistream = isEnableRealtimeThroughOptistream
        self.isProductionLogsEnabled = isProductionLogsEnabled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnableRealtime = try container.decode(Bool.self, forKey: .enableRealtime)
        isProductionLogsEnabled = try container.decodeIfPresent(Bool.self, forKey: .prodLogsEnabled) ?? false
        isEnableRealtimeThroughOptistream = try container.decodeIfPresent(Bool.self, forKey: .enableRealtimeThroughOptistream) ?? false
        realtime = try container.decode(TenantRealtimeConfig.self, forKey: .realtime)
        optitrack = try container.decode(TenantOptitrackConfig.self, forKey: .optitrack)
        events = try container.decode([String: EventsConfig].self, forKey: .events)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(isProductionLogsEnabled, forKey: .prodLogsEnabled)
        try container.encode(isEnableRealtime, forKey: .enableRealtime)
        try container.encodeIfPresent(isEnableRealtimeThroughOptistream, forKey: .enableRealtimeThroughOptistream)
        try container.encode(realtime, forKey: .realtime)
        try container.encode(optitrack, forKey: .optitrack)
        try container.encode(events, forKey: .events)
    }

    enum CodingKeys: String, CodingKey {
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
