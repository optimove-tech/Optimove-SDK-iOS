//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveSDK

public final class TenantConfigFixture {
    public init() {}

    public func build(_ options: Options = Options.default) -> TenantConfig {
        return TenantConfig(
            realtime: tenantRealtimeConfigFixture(),
            optitrack: tenantOptitrackConfigFixture(),
            events: createTenantEventFixture(),
            isEnableRealtime: options.isEnableRealtime,
            isSupportedAirship: false,
            isEnableRealtimeThroughOptistream: options.isEnableRealtimeThroughOptistream,
            isProductionLogsEnabled: false
        )
    }

    public func tenantRealtimeConfigFixture() -> TenantRealtimeConfig {
        return TenantRealtimeConfig(
            realtimeGateway: StubVariables.url
        )
    }

    public func tenantOptitrackConfigFixture() -> TenantOptitrackConfig {
        return TenantOptitrackConfig(
            optitrackEndpoint: StubVariables.url,
            siteId: StubVariables.int
        )
    }

    public func createTenantEventFixture() -> [String: EventsConfig] {
        return [
            StubEvent.Constnats.name: EventsConfig(
                id: StubEvent.Constnats.id,
                supportedOnOptitrack: true,
                supportedOnRealTime: true,
                parameters: [
                    StubEvent.Constnats.key: Parameter(
                        type: "String",
                        optional: false
                    ),
                    "event_platform": Parameter(
                        type: "String",
                        optional: true
                    ),
                    "event_device_type": Parameter(
                        type: "String",
                        optional: true
                    ),
                    "event_os": Parameter(
                        type: "String",
                        optional: true
                    ),
                    "event_native_mobile": Parameter(
                        type: "Boolean",
                        optional: true
                    ),
                ]
            ),
        ]
    }
}
