//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
@testable import OptimoveCore

let tenantConfigFixture: () -> TenantConfig = {
    return TenantConfig(
        realtime: tenantRealtimeConfigFixture(),
        optitrack: tenantOptitrackConfigFixture(),
        optipush: tenantOptipushConfigFixture(),
        firebaseProjectKeys: firebaseProjectKeysFixutre(),
        clientsServiceProjectKeys: clientsServiceProjectKeysFixutre(),
        events: tenantEventsFixture()
    )
}

let tenantRealtimeConfigFixture: () -> TenantRealtimeConfig = {
    return TenantRealtimeConfig(
        realtimeToken: "realtimeToken",
        realtimeGateway: StubVariables.url
    )
}

let tenantOptitrackConfigFixture: () -> TenantOptitrackConfig = {
    return TenantOptitrackConfig(
        optitrackEndpoint: StubVariables.url,
        siteId: StubVariables.int
    )
}

let tenantOptipushConfigFixture: () -> TenantOptipushConfig = {
    return TenantOptipushConfig(
        pushTopicsRegistrationEndpoint: StubVariables.url,
        enableAdvertisingIdReport: StubVariables.bool
    )
}

let tenantEventsFixture: () -> [String : EventsConfig] = {
    return [
        "tenant_event": EventsConfig(
            id: Int(Int16.max),
            supportedOnOptitrack: StubVariables.bool,
            supportedOnRealTime: StubVariables.bool,
            parameters: [
                "tenant_event_parameter": Parameter(
                    type: "tenant_event_parameter_type",
                    optiTrackDimensionId: Int(Int8.max),
                    optional: false
                )
            ]
        )
    ]
}
