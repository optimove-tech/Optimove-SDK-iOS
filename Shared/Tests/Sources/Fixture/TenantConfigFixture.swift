//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class TenantConfigFixture {

    func build() -> TenantConfig {
        return TenantConfig(
            realtime: tenantRealtimeConfigFixture(),
            optitrack: tenantOptitrackConfigFixture(),
            optipush: tenantOptipushConfigFixture(),
            events: createTenantEventFixture(),
            isSupportedAirship: nil
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
