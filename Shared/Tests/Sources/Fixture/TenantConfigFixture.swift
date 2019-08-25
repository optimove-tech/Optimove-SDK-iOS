//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class TenantConfigFixture {

    func build() -> TenantConfig {
        return TenantConfig(
            realtime: tenantRealtimeConfigFixture(),
            optitrack: tenantOptitrackConfigFixture(),
            optipush: tenantOptipushConfigFixture(),
            firebaseProjectKeys: firebaseProjectKeysFixture(),
            clientsServiceProjectKeys: clientsServiceProjectKeysFixture(),
            events: createTenantEventFixture()
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

    func firebaseProjectKeysFixture() -> FirebaseProjectKeys {
        return FirebaseProjectKeys(
            appid: StubVariables.string,
            webApiKey: StubVariables.string,
            dbUrl: StubVariables.string,
            senderId: StubVariables.string,
            storageBucket: StubVariables.string,
            projectId: StubVariables.string
        )
    }

    func clientsServiceProjectKeysFixture() -> ClientsServiceProjectKeys {
        return ClientsServiceProjectKeys(
            appid: StubVariables.string,
            webApiKey: StubVariables.string,
            dbUrl: StubVariables.string,
            senderId: StubVariables.string,
            storageBucket: StubVariables.string,
            projectId: StubVariables.string
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
                        optiTrackDimensionId: 20,
                        optional: false
                    ),
                    "event_platform": Parameter(
                        type: "String",
                        optiTrackDimensionId: 11,
                        optional: true
                    ),
                    "event_device_type": Parameter(
                        type: "String",
                        optiTrackDimensionId: 12,
                        optional: true
                    ),
                    "event_os": Parameter(
                        type: "String",
                        optiTrackDimensionId: 13,
                        optional: true
                    ),
                    "event_native_mobile": Parameter(
                        type: "Boolean",
                        optiTrackDimensionId: 14,
                        optional: true
                    )
                ]
            )
        ]
    }

}
