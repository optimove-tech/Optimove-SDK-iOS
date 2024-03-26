//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
@testable import OptimoveSDK

public final class GlobalConfigFixture: FileAccessible {
    public let fileName: String = "core_events.json"
    private var events: [String: EventsConfig] = [:]

    public init() {
        events = try! JSONDecoder().decode([String: EventsConfig].self, from: data)
    }

    public func build() -> GlobalConfig {
        return GlobalConfig(
            general: generalConfigFuxture(),
            optitrack: optitrackConfigFixture(),
            coreEvents: coreEventFixture()
        )
    }

    public func generalConfigFuxture() -> GlobalGeneralConfig {
        return GlobalGeneralConfig(
            logsServiceEndpoint: StubVariables.url
        )
    }

    public func optitrackConfigFixture() -> GlobalOptitrackConfig {
        return GlobalOptitrackConfig(
            eventCategoryName: "event_category_name"
        )
    }

    public func coreEventFixture() -> [String: EventsConfig] {
        return events
    }
}
