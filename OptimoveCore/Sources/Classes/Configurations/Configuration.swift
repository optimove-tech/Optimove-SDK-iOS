//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public struct Configuration: Codable, TenantInfo, EventInfo {
    public let tenantID: Int
    public let logger: LoggerConfig
    public let realtime: RealtimeConfig
    public let optitrack: OptitrackConfig
    public let events: [String: EventsConfig]
    public let isEnableRealtime: Bool

    public init(
        tenantID: Int,
        logger: LoggerConfig,
        realtime: RealtimeConfig,
        optitrack: OptitrackConfig,
        events: [String: EventsConfig],
        isEnableRealtime: Bool
    ) {
        self.tenantID = tenantID
        self.logger = logger
        self.realtime = realtime
        self.optitrack = optitrack
        self.events = events
        self.isEnableRealtime = isEnableRealtime
    }
}

public struct LoggerConfig: Codable, TenantInfo {
    public let tenantID: Int
    public let logServiceEndpoint: URL
    public let isProductionLogsEnabled: Bool

    public init(
        tenantID: Int,
        logServiceEndpoint: URL,
        isProductionLogsEnabled: Bool) {
        self.tenantID = tenantID
        self.logServiceEndpoint = logServiceEndpoint
        self.isProductionLogsEnabled = isProductionLogsEnabled
    }
}

public struct RealtimeConfig: Codable, TenantInfo, EventInfo {
    public let tenantID: Int
    public let realtimeGateway: URL
    public let events: [String: EventsConfig]
    public let isEnableRealtimeThroughOptistream: Bool

    public init(
        tenantID: Int,
        realtimeGateway: URL,
        events: [String: EventsConfig],
        isEnableRealtimeThroughOptistream: Bool
    ) {
        self.tenantID = tenantID
        self.realtimeGateway = realtimeGateway
        self.events = events
        self.isEnableRealtimeThroughOptistream = isEnableRealtimeThroughOptistream
    }
}

public struct OptitrackConfig: Codable, TenantInfo, EventInfo {
    public let tenantID: Int
    public let optitrackEndpoint: URL
    public let enableAdvertisingIdReport: Bool
    public let eventCategoryName: String
    public let events: [String: EventsConfig]
    public let isEnableRealtime: Bool
    public let maxActionCustomDimensions: Int

    public init(
        tenantID: Int,
        optitrackEndpoint: URL,
        enableAdvertisingIdReport: Bool,
        eventCategoryName: String,
        events: [String: EventsConfig],
        isEnableRealtime: Bool,
        maxActionCustomDimensions: Int
    ) {
        self.tenantID = tenantID
        self.optitrackEndpoint = optitrackEndpoint
        self.enableAdvertisingIdReport = enableAdvertisingIdReport
        self.eventCategoryName = eventCategoryName
        self.events = events
        self.isEnableRealtime = isEnableRealtime
        self.maxActionCustomDimensions = maxActionCustomDimensions
    }
}

public protocol TenantInfo {
    var tenantID: Int { get }
}

public protocol EventInfo {
    var events: [String: EventsConfig] { get }
}
