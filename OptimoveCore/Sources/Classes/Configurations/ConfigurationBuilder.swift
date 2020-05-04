//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public final class ConfigurationBuilder {

    private let globalConfig: GlobalConfig
    private let tenantConfig: TenantConfig
    private let events: [String: EventsConfig]

    public init(globalConfig: GlobalConfig,
         tenantConfig: TenantConfig) {
        self.globalConfig = globalConfig
        self.tenantConfig = tenantConfig
        events = globalConfig.coreEvents.merging(
            tenantConfig.events,
            uniquingKeysWith: { globalEvent, tenantEvent in globalEvent }
        )
    }

    public func build() -> Configuration {
        return Configuration(
            tenantID: tenantConfig.optitrack.siteId,
            logger: buildLoggerConfig(),
            realtime: buildRealtimeConfig(),
            optitrack: buildOptitrackConfig(),
            optipush: buildOptipushConfig(),
            events: events,
            isEnableRealtime: tenantConfig.isEnableRealtime,
            isSupportedAirship: tenantConfig.isSupportedAirship
        )
    }

}

private extension ConfigurationBuilder {

    func buildLoggerConfig() -> LoggerConfig {
        return LoggerConfig(
            tenantID: tenantConfig.optitrack.siteId,
            logServiceEndpoint: globalConfig.general.logsServiceEndpoint
        )
    }

    func buildRealtimeConfig() -> RealtimeConfig {
        return RealtimeConfig(
            tenantID: tenantConfig.optitrack.siteId,
            realtimeToken: tenantConfig.realtime.realtimeToken,
            realtimeGateway: tenantConfig.realtime.realtimeGateway,
            events: events,
            isEnableRealtimeThroughOptistream: tenantConfig.isEnableRealtimeThroughOptistream
        )
    }

    func buildOptitrackConfig() -> OptitrackConfig {
        return OptitrackConfig(
            tenantID: tenantConfig.optitrack.siteId,
            optitrackEndpoint: tenantConfig.optitrack.optitrackEndpoint,
            enableAdvertisingIdReport: tenantConfig.optipush.enableAdvertisingIdReport,
            eventCategoryName: globalConfig.optitrack.eventCategoryName,
            customDimensionIDS: globalConfig.optitrack.customDimensionIDs,
            events: events,
            isEnableRealtimeThroughOptistream: tenantConfig.isEnableRealtimeThroughOptistream
        )
    }

    func buildOptipushConfig() -> OptipushConfig {
        return OptipushConfig(
            tenantID: tenantConfig.optitrack.siteId,
            mbaasEndpoint: globalConfig.optipush.mbaasEndpoint,
            pushTopicsRegistrationEndpoint: tenantConfig.optipush.pushTopicsRegistrationEndpoint
        )
    }

}
