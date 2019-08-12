//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

struct Configuration: Codable, TenantInfo {
    let tenantID: Int
    let logger: LoggerConfig
    let realtime: RealtimeConfig
    let optitrack: OptitrackConfig
    let optipush: OptipushConfig
}

struct LoggerConfig: Codable, TenantInfo {
    let tenantID: Int
    let logServiceEndpoint: URL
}

struct RealtimeConfig: Codable, TenantInfo {
    let tenantID: Int
    let realtimeToken: String
    let realtimeGateway: URL
}

struct OptitrackConfig: Codable, TenantInfo {
    let tenantID: Int
    let optitrackEndpoint: URL
    let enableAdvertisingIdReport: Bool
    let eventCategoryName: String
    let customDimensionIDS: CustomDimensionIDs
}

struct OptipushConfig: Codable, TenantInfo {
    let tenantID: Int
    let registrationServiceEndpoint: URL
    let pushTopicsRegistrationEndpoint: URL
    let firebaseProjectKeys: FirebaseProjectKeys
    let clientsServiceProjectKeys: ClientsServiceProjectKeys
}

protocol TenantInfo {
    var tenantID: Int { get }
}
