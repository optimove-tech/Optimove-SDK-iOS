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
            eventCategoryName: "event_category_name",
            customDimensionIDs: customDimensionIDsFixture()
        )
    }

    func optipushConfigFixture() -> GlobalOptipushConfig {
        return GlobalOptipushConfig(
            registrationServiceEndpoint: StubVariables.url,
            mbaasEndpoint: StubVariables.url
        )
    }

    func customDimensionIDsFixture() -> CustomDimensionIDs {
        return CustomDimensionIDs(
            eventIDCustomDimensionID: 6,
            eventNameCustomDimensionID: 7,
            visitCustomDimensionsStartID: 1,
            maxVisitCustomDimensions: 5,
            actionCustomDimensionsStartID: 8,
            maxActionCustomDimensions: 25
        )
    }

    func coreEventFixture() -> [String: EventsConfig] {
        return events
    }
}
