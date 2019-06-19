import Foundation

struct TenantConfig: Decodable {
    let version: String
    let enableOptitrack: Bool
    let enableOptipush: Bool
    let enableVisitors: Bool
    let enableRealtime: Bool
    let siteID: Int
    let realtimeMetaData: RealtimeMetaData?
    var optitrackMetaData: OptitrackMetaData?
    let optipushMetaData: OptipushMetaData?
    let firebaseProjectKeys: FirebaseProjectKeys?
    let clientsServiceProjectKeys: ClientsServiceProjectKeys?
    let events: [String: OptimoveEventConfig]

    init(from decoder: Decoder) throws {

        let values = try decoder.container(keyedBy: CodingKeys.self)
        version = try values.decode(String.self, forKey: .version)
        enableOptitrack = try values.decode(Bool.self, forKey: .enableOptitrack)
        enableOptipush = try values.decode(Bool.self, forKey: .enableOptipush)
        enableVisitors = try values.decode(Bool.self, forKey: .enableVisitors)
        enableRealtime = try values.decode(Bool.self, forKey: .enableRealtime)
        realtimeMetaData = try? values.decode(RealtimeMetaData.self, forKey: .realtimeMetaData)
        let s = try values.nestedContainer(keyedBy: CodingKeys.self, forKey: .optitrackMetaData)
        siteID = try s.decode(Int.self, forKey: .siteId)

        optitrackMetaData = try? values.decode(OptitrackMetaData.self, forKey: .optitrackMetaData)

        let mobile = try values.nestedContainer(keyedBy: AdditionalInfoKeys.self, forKey: .mobile)
        optipushMetaData = try? mobile.decode(OptipushMetaData.self, forKey: .optipushMetaData)
        firebaseProjectKeys = try? mobile.decode(FirebaseProjectKeys.self, forKey: .firebaseProjectKeys)
        clientsServiceProjectKeys = try? mobile.decode(
            ClientsServiceProjectKeys.self,
            forKey: .clientsServiceProjectKeys
        )

        events = try values.decode([String: OptimoveEventConfig].self, forKey: .events)

        if let enableIdfa = optipushMetaData?.enableAdvertisingIdReport {
            optitrackMetaData?.enableAdvertisingIdReport = enableIdfa
        } else {
            OptiLoggerMessages.logIdfaPermissionMissing()
            optitrackMetaData = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case version
        case enableOptitrack
        case enableOptipush
        case enableVisitors
        case enableRealtime
        case realtimeMetaData
        case optitrackMetaData
        case mobile
        case events
        case siteId
    }

    enum AdditionalInfoKeys: String, CodingKey {
        case optitrackMetaData
        case optipushMetaData
        case firebaseProjectKeys
        case clientsServiceProjectKeys
    }
}
