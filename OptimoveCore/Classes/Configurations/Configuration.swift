//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public struct Configuration: Codable, TenantInfo, EventInfo {
    public let tenantID: Int
    public let logger: LoggerConfig
    public let realtime: RealtimeConfig
    public let optitrack: OptitrackConfig
    public let optipush: OptipushConfig
    public let events: [String : EventsConfig]
}

public struct LoggerConfig: Codable, TenantInfo {
    public let tenantID: Int
    public let logServiceEndpoint: URL
}

public struct RealtimeConfig: Codable, TenantInfo, EventInfo {
    public let tenantID: Int
    public let realtimeToken: String
    public let realtimeGateway: URL
    public let events: [String : EventsConfig]
}

public struct OptitrackConfig: Codable, TenantInfo, EventInfo {
    public let tenantID: Int
    public let optitrackEndpoint: URL
    public let enableAdvertisingIdReport: Bool
    public let eventCategoryName: String
    public let customDimensionIDS: CustomDimensionIDs
    public let events: [String : EventsConfig]
}

public struct OptipushConfig: Codable, TenantInfo {
    public let tenantID: Int
    public let registrationServiceEndpoint: URL
    public let pushTopicsRegistrationEndpoint: URL
    public let firebaseProjectKeys: FirebaseProjectKeys
    public let clientsServiceProjectKeys: ClientsServiceProjectKeys
}

public protocol TenantInfo {
    var tenantID: Int { get }
}

public protocol EventInfo {
    var events: [String : EventsConfig] { get }
}
