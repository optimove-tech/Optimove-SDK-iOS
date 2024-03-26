//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

struct Configuration: Codable, TenantInfo, EventInfo {
    let tenantID: Int
    let logger: LoggerConfig
    let realtime: RealtimeConfig
    let optitrack: OptitrackConfig
    let events: [String: EventsConfig]
    let isEnableRealtime: Bool
    let isSupportedAirship: Bool

    init(
        tenantID: Int,
        logger: LoggerConfig,
        realtime: RealtimeConfig,
        optitrack: OptitrackConfig,
        events: [String: EventsConfig],
        isEnableRealtime: Bool,
        isSupportedAirship: Bool
    ) {
        self.tenantID = tenantID
        self.logger = logger
        self.realtime = realtime
        self.optitrack = optitrack
        self.events = events
        self.isEnableRealtime = isEnableRealtime
        self.isSupportedAirship = isSupportedAirship
    }
}

struct LoggerConfig: Codable, TenantInfo {
    let tenantID: Int
    let logServiceEndpoint: URL
    let isProductionLogsEnabled: Bool

    init(
        tenantID: Int,
        logServiceEndpoint: URL,
        isProductionLogsEnabled: Bool
    ) {
        self.tenantID = tenantID
        self.logServiceEndpoint = logServiceEndpoint
        self.isProductionLogsEnabled = isProductionLogsEnabled
    }
}

struct RealtimeConfig: Codable, TenantInfo, EventInfo {
    let tenantID: Int
    let realtimeGateway: URL
    let events: [String: EventsConfig]
    let isEnableRealtimeThroughOptistream: Bool

    init(
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

struct OptitrackConfig: Codable, TenantInfo, EventInfo {
    let tenantID: Int
    let optitrackEndpoint: URL
    let enableAdvertisingIdReport: Bool
    let eventCategoryName: String
    let events: [String: EventsConfig]
    let isEnableRealtime: Bool

    init(
        tenantID: Int,
        optitrackEndpoint: URL,
        enableAdvertisingIdReport: Bool,
        eventCategoryName: String,
        events: [String: EventsConfig],
        isEnableRealtime: Bool
    ) {
        self.tenantID = tenantID
        self.optitrackEndpoint = optitrackEndpoint
        self.enableAdvertisingIdReport = enableAdvertisingIdReport
        self.eventCategoryName = eventCategoryName
        self.events = events
        self.isEnableRealtime = isEnableRealtime
    }
}

protocol TenantInfo {
    var tenantID: Int { get }
}

protocol EventInfo {
    var events: [String: EventsConfig] { get }
}
