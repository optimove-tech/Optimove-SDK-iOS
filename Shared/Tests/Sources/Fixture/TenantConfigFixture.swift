//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
@testable import OptimoveCore

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
                id: 2_000,
                supportedOnOptitrack: true,
                supportedOnRealTime: true,
                parameters: [
                    StubEvent.Constnats.key: Parameter(
                        type: "String",
                        optiTrackDimensionId: 20,
                        optional: false
                    )
                ]
            )
        ]
    }

}
