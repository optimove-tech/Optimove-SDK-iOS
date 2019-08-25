//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public struct Configuration: Codable, TenantInfo, EventInfo {
    public let tenantID: Int
    public let logger: LoggerConfig
    public let realtime: RealtimeConfig
    public let optitrack: OptitrackConfig
    public let optipush: OptipushConfig
    public let events: [String: EventsConfig]

    public init(
        tenantID: Int,
        logger: LoggerConfig,
        realtime: RealtimeConfig,
        optitrack: OptitrackConfig,
        optipush: OptipushConfig,
        events: [String: EventsConfig]) {
        self.tenantID = tenantID
        self.logger = logger
        self.realtime = realtime
        self.optitrack = optitrack
        self.optipush = optipush
        self.events = events
    }
}

public struct LoggerConfig: Codable, TenantInfo {
    public let tenantID: Int
    public let logServiceEndpoint: URL

    public init(
        tenantID: Int,
        logServiceEndpoint: URL) {
        self.tenantID = tenantID
        self.logServiceEndpoint = logServiceEndpoint
    }
}

public struct RealtimeConfig: Codable, TenantInfo, EventInfo {
    public let tenantID: Int
    public let realtimeToken: String
    public let realtimeGateway: URL
    public let events: [String: EventsConfig]

    public init(
        tenantID: Int,
        realtimeToken: String,
        realtimeGateway: URL,
        events: [String: EventsConfig]) {
        self.tenantID = tenantID
        self.realtimeToken = realtimeToken
        self.realtimeGateway = realtimeGateway
        self.events = events
    }
}

public struct OptitrackConfig: Codable, TenantInfo, EventInfo {
    public let tenantID: Int
    public let optitrackEndpoint: URL
    public let enableAdvertisingIdReport: Bool
    public let eventCategoryName: String
    public let customDimensionIDS: CustomDimensionIDs
    public let events: [String: EventsConfig]

    public init(
        tenantID: Int,
        optitrackEndpoint: URL,
        enableAdvertisingIdReport: Bool,
        eventCategoryName: String,
        customDimensionIDS: CustomDimensionIDs,
        events: [String: EventsConfig]) {
        self.tenantID = tenantID
        self.optitrackEndpoint = optitrackEndpoint
        self.enableAdvertisingIdReport = enableAdvertisingIdReport
        self.eventCategoryName = eventCategoryName
        self.customDimensionIDS = customDimensionIDS
        self.events = events
    }
}

public struct OptipushConfig: Codable, TenantInfo {
    public let tenantID: Int
    public let registrationServiceEndpoint: URL
    public let pushTopicsRegistrationEndpoint: URL
    public let firebaseProjectKeys: FirebaseProjectKeys
    public let clientsServiceProjectKeys: ClientsServiceProjectKeys

    public init(
        tenantID: Int,
        registrationServiceEndpoint: URL,
        pushTopicsRegistrationEndpoint: URL,
        firebaseProjectKeys: FirebaseProjectKeys,
        clientsServiceProjectKeys: ClientsServiceProjectKeys) {
        self.tenantID = tenantID
        self.registrationServiceEndpoint = registrationServiceEndpoint
        self.pushTopicsRegistrationEndpoint = pushTopicsRegistrationEndpoint
        self.firebaseProjectKeys = firebaseProjectKeys
        self.clientsServiceProjectKeys = clientsServiceProjectKeys
    }
}

public protocol TenantInfo {
    var tenantID: Int { get }
}

public protocol EventInfo {
    var events: [String: EventsConfig] { get }
}
