//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class TenantConfigFixture {

    func build(_ options: Options = Options.default) -> TenantConfig {
        return TenantConfig(
            realtime: tenantRealtimeConfigFixture(),
            optitrack: tenantOptitrackConfigFixture(),
            optipush: tenantOptipushConfigFixture(),
            events: createTenantEventFixture(),
            isEnableRealtime: options.isEnableRealtime,
            isSupportedAirship: false,
            isEnableRealtimeThroughOptistream: options.isEnableRealtimeThroughOptistream
        )
    }

    func tenantRealtimeConfigFixture() -> TenantRealtimeConfig {
        return TenantRealtimeConfig(
            realtimeToken: "realtimeToken",
            realtimeGateway: StubVariables.url
        )
    }

    func tenantOptitrackConfigFixture() -> TenantOptitrackConfig {
        return TenantOptitrackConfig(
            optitrackEndpoint: StubVariables.url,
            siteId: StubVariables.int
        )
    }

    func tenantOptipushConfigFixture() -> TenantOptipushConfig {
        return TenantOptipushConfig(
            pushTopicsRegistrationEndpoint: StubVariables.url,
            enableAdvertisingIdReport: StubVariables.bool
        )
    }

    func createTenantEventFixture() -> [String: EventsConfig] {
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
                    )
                ]
            )
        ]
    }

}
