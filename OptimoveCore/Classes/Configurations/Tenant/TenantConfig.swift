//  Copyright © 2017 Optimove. All rights reserved.

public struct TenantConfig: Codable {
    let realtime: TenantRealtimeConfig
    var optitrack: TenantOptitrackConfig
    let optipush: TenantOptipushConfig
    let firebaseProjectKeys: FirebaseProjectKeys
    let clientsServiceProjectKeys: ClientsServiceProjectKeys
    let events: [String: EventsConfig]

    init(realtime: TenantRealtimeConfig,
         optitrack: TenantOptitrackConfig,
         optipush: TenantOptipushConfig,
         firebaseProjectKeys: FirebaseProjectKeys,
         clientsServiceProjectKeys: ClientsServiceProjectKeys,
         events: [String : EventsConfig]) {
        self.realtime = realtime
        self.optitrack = optitrack
        self.optipush = optipush
        self.firebaseProjectKeys = firebaseProjectKeys
        self.clientsServiceProjectKeys = clientsServiceProjectKeys
        self.events = events
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        realtime = try container.decode(TenantRealtimeConfig.self, forKey: .realtime)
        optitrack = try container.decode(TenantOptitrackConfig.self, forKey: .optitrack)
        events = try container.decode([String: EventsConfig].self, forKey: .events)
        let mobile = try container.nestedContainer(keyedBy: MobileCodingKey.self, forKey: .mobile)
        optipush = try mobile.decode(TenantOptipushConfig.self, forKey: .optipush)
        firebaseProjectKeys = try mobile.decode(FirebaseProjectKeys.self, forKey: .firebaseProjectKeys)
        clientsServiceProjectKeys = try mobile.decode(ClientsServiceProjectKeys.self, forKey: .clientsServiceProjectKeys)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(realtime, forKey: .realtime)
        try container.encode(optitrack, forKey: .optitrack)
        try container.encode(events, forKey: .events)
        var mobile =  container.nestedContainer(keyedBy: MobileCodingKey.self, forKey: .mobile)
        try mobile.encode(optipush, forKey: .optipush)
        try mobile.encode(firebaseProjectKeys, forKey: .firebaseProjectKeys)
        try mobile.encode(clientsServiceProjectKeys, forKey: .clientsServiceProjectKeys)
    }

    enum CodingKeys: String, CodingKey {
        case realtime = "realtimeMetaData"
        case optitrack = "optitrackMetaData"
        case mobile
        case events
        case siteId
    }

    enum MobileCodingKey: String, CodingKey {
        case optipush = "optipushMetaData"
        case firebaseProjectKeys
        case clientsServiceProjectKeys
    }
}
