//  Copyright © 2017 Optimove. All rights reserved.

public struct TenantConfig: Codable, Equatable {
    public let isSupportedAirship: Bool?
    public var optitrack: TenantOptitrackConfig
    public let optipush: TenantOptipushConfig
    public let events: [String: EventsConfig]

    public init(
        optitrack: TenantOptitrackConfig,
        optipush: TenantOptipushConfig,
        events: [String: EventsConfig],
        isSupportedAirship: Bool?
    ) {
        self.optitrack = optitrack
        self.optipush = optipush
        self.events = events
        self.isSupportedAirship = isSupportedAirship
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isSupportedAirship = try container.decodeIfPresent(Bool.self, forKey: .supportAirship)
        optitrack = try container.decode(TenantOptitrackConfig.self, forKey: .optitrack)
        events = try container.decode([String: EventsConfig].self, forKey: .events)
        let mobile = try container.nestedContainer(keyedBy: MobileCodingKey.self, forKey: .mobile)
        optipush = try mobile.decode(TenantOptipushConfig.self, forKey: .optipush)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(optitrack, forKey: .optitrack)
        try container.encode(events, forKey: .events)
        var mobile = container.nestedContainer(keyedBy: MobileCodingKey.self, forKey: .mobile)
        try mobile.encode(optipush, forKey: .optipush)
    }

    enum CodingKeys: String, CodingKey {
        case supportAirship
        case optitrack = "optitrackMetaData"
        case mobile
        case events
        case siteId
    }

    enum MobileCodingKey: String, CodingKey {
        case optipush = "optipushMetaData"
    }
}
