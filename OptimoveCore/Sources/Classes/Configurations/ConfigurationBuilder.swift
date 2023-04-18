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
            logServiceEndpoint: globalConfig.general.logsServiceEndpoint,
            isProductionLogsEnabled: tenantConfig.isProductionLogsEnabled
        )
    }

    func buildRealtimeConfig() -> RealtimeConfig {
        return RealtimeConfig(
            tenantID: tenantConfig.optitrack.siteId,
            realtimeGateway: tenantConfig.realtime.realtimeGateway,
            events: events,
            isEnableRealtimeThroughOptistream: tenantConfig.isEnableRealtimeThroughOptistream
        )
    }

    func buildOptitrackConfig() -> OptitrackConfig {
        return OptitrackConfig(
            tenantID: tenantConfig.optitrack.siteId,
            optitrackEndpoint: tenantConfig.optitrack.optitrackEndpoint,
            // TODO: explore removal of this flag
            enableAdvertisingIdReport: false,
            eventCategoryName: globalConfig.optitrack.eventCategoryName,
            events: events,
            isEnableRealtime: tenantConfig.isEnableRealtime && tenantConfig.isEnableRealtimeThroughOptistream
        )
    }

}
