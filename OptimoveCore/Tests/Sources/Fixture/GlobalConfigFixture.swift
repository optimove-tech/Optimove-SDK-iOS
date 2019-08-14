//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
@testable import OptimoveCore

let globalConfigFixture: () ->  GlobalConfig = {
    return GlobalConfig(
        general: globalGeneralConfigFuxture(),
        optitrack: globalOptitrackConfigFixture(),
        optipush: globalOptipushConfigFixture(),
        coreEvents: coreEventsFixture()
    )
}

let globalGeneralConfigFuxture: () -> GlobalGeneralConfig = {
    return GlobalGeneralConfig(
        logsServiceEndpoint: StubVariables.url
    )
}

let globalOptitrackConfigFixture: () -> GlobalOptitrackConfig = {
    return GlobalOptitrackConfig(
        eventCategoryName: "event_category_name",
        customDimensionIDs: customDimensionIDsFixture()
    )
}

let globalOptipushConfigFixture: () -> GlobalOptipushConfig = {
    return GlobalOptipushConfig(
        registrationServiceEndpoint: StubVariables.url
    )
}

let coreEventsFixture: () -> [String : EventsConfig] = {
    return [
        "core_event": EventsConfig(
            id: Int(Int16.max),
            supportedOnOptitrack: StubVariables.bool,
            supportedOnRealTime: StubVariables.bool,
            parameters: [
                "core_event_parameter": Parameter(
                    type: "core_event_parameter_type",
                    optiTrackDimensionId: Int(Int8.max),
                    optional: false
                )
            ]
        )
    ]
}
