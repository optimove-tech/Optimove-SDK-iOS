//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
@testable import OptimoveCore

final class GlobalConfigFixture: FileAccessible {

    let fileName: String = "core_events.json"
    private var events: [String: EventsConfig] = [:]

    init() {
        events = try! JSONDecoder().decode([String: EventsConfig].self, from: data)
    }

    func build() -> GlobalConfig {
        return GlobalConfig(
            general: generalConfigFuxture(),
            optitrack: optitrackConfigFixture(),
            optipush: optipushConfigFixture(),
            coreEvents: coreEventFixture()
        )
    }

    func generalConfigFuxture() -> GlobalGeneralConfig {
        return GlobalGeneralConfig(
            logsServiceEndpoint: StubVariables.url
        )
    }

    func optitrackConfigFixture() -> GlobalOptitrackConfig {
        return GlobalOptitrackConfig(
            eventCategoryName: "event_category_name"
        )
    }

    func optipushConfigFixture() -> GlobalOptipushConfig {
        return GlobalOptipushConfig(
            mbaasEndpoint: StubVariables.url
        )
    }

    func coreEventFixture() -> [String: EventsConfig] {
        return events
    }
}
