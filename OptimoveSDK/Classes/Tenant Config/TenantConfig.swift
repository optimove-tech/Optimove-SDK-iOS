import Foundation

struct TenantConfig: Codable {
    let version: String
    let enableVisitors: Bool
    let realtimeMetaData: RealtimeMetaData?
    var optitrackMetaData: OptitrackMetaData?
    let optipushMetaData: OptipushMetaData?
    let firebaseProjectKeys: FirebaseProjectKeys?
    let clientsServiceProjectKeys: ClientsServiceProjectKeys?
    let events: [String: EventsConfig]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        version = try container.decode(String.self, forKey: .version)
        enableVisitors = try container.decode(Bool.self, forKey: .enableVisitors)

        realtimeMetaData = try container.decodeIfPresent(RealtimeMetaData.self, forKey: .realtimeMetaData)
        optitrackMetaData = try container.decodeIfPresent(OptitrackMetaData.self, forKey: .optitrackMetaData)

        events = try container.decode([String: EventsConfig].self, forKey: .events)

        // mobile
        let mobile = try container.nestedContainer(keyedBy: MobileCodingKey.self, forKey: .mobile)
        optipushMetaData = try mobile.decodeIfPresent(OptipushMetaData.self, forKey: .optipushMetaData)
        firebaseProjectKeys = try mobile.decodeIfPresent(FirebaseProjectKeys.self, forKey: .firebaseProjectKeys)
        clientsServiceProjectKeys = try mobile.decodeIfPresent(
            ClientsServiceProjectKeys.self,
            forKey: .clientsServiceProjectKeys
        )

        // By historical reason, the `enableAdvertisingIdReport` flag was added to
        // `optipushMetaData` instead of `optitrackMetaData`.
        // If `optipushMetaData` will be nil, that means config is broken and
        // the whole `optitrackMetaData` should be wiped.
        if let enableIdfa = optipushMetaData?.enableAdvertisingIdReport {
            optitrackMetaData?.enableAdvertisingIdReport = enableIdfa
        } else {
            OptiLoggerMessages.logIdfaPermissionMissing()
            optitrackMetaData = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(enableVisitors, forKey: .enableVisitors)

        try container.encodeIfPresent(realtimeMetaData, forKey: .realtimeMetaData)
        try container.encodeIfPresent(optitrackMetaData, forKey: .optitrackMetaData)

        try container.encode(events, forKey: .events)

        var mobile =  container.nestedContainer(keyedBy: MobileCodingKey.self, forKey: .mobile)
        try mobile.encodeIfPresent(optipushMetaData, forKey: .optipushMetaData)
        try mobile.encodeIfPresent(firebaseProjectKeys, forKey: .firebaseProjectKeys)
        try mobile.encodeIfPresent(clientsServiceProjectKeys, forKey: .clientsServiceProjectKeys)
    }

    enum CodingKeys: String, CodingKey {
        case version
        case enableVisitors
        case realtimeMetaData
        case optitrackMetaData
        case mobile
        case events
        case siteId
    }

    enum MobileCodingKey: String, CodingKey {
        case optitrackMetaData
        case optipushMetaData
        case firebaseProjectKeys
        case clientsServiceProjectKeys
    }
}
