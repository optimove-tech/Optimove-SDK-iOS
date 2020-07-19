//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public struct Configuration: Codable, TenantInfo, EventInfo {
    public let tenantID: Int
    public let logger: LoggerConfig
    public let realtime: RealtimeConfig
    public let optitrack: OptitrackConfig
    public let optipush: OptipushConfig
    public let events: [String: EventsConfig]
    public let isEnableRealtime: Bool
    public let isSupportedAirship: Bool

    public init(
        tenantID: Int,
        logger: LoggerConfig,
        realtime: RealtimeConfig,
        optitrack: OptitrackConfig,
        optipush: OptipushConfig,
        events: [String: EventsConfig],
        isEnableRealtime: Bool,
        isSupportedAirship: Bool
    ) {
        self.tenantID = tenantID
        self.logger = logger
        self.realtime = realtime
        self.optitrack = optitrack
        self.optipush = optipush
        self.events = events
        self.isEnableRealtime = isEnableRealtime
        self.isSupportedAirship = isSupportedAirship
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
    public let isEnableRealtimeThroughOptistream: Bool

    public init(
        tenantID: Int,
        realtimeToken: String,
        realtimeGateway: URL,
        events: [String: EventsConfig],
        isEnableRealtimeThroughOptistream: Bool
    ) {
        self.tenantID = tenantID
        self.realtimeToken = realtimeToken
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

public struct OptipushConfig: Codable, TenantInfo {
    public let tenantID: Int
    public let mbaasEndpoint: URL
    public let pushTopicsRegistrationEndpoint: URL

    public init(
        tenantID: Int,
        mbaasEndpoint: URL,
        pushTopicsRegistrationEndpoint: URL) {
        self.tenantID = tenantID
        self.mbaasEndpoint = mbaasEndpoint
        self.pushTopicsRegistrationEndpoint = pushTopicsRegistrationEndpoint
    }
}

public protocol TenantInfo {
    var tenantID: Int { get }
}

public protocol EventInfo {
    var events: [String: EventsConfig] { get }
}
