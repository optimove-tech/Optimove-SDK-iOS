//  Copyright © 2017 Optimove. All rights reserved.

struct EventsConfig: Codable, Equatable {
    let id: Int
    let supportedOnOptitrack: Bool
    let supportedOnRealTime: Bool
    let parameters: [String: Parameter]

    init(
        id: Int,
        supportedOnOptitrack: Bool,
        supportedOnRealTime: Bool,
        parameters: [String: Parameter]
    ) {
        self.id = id
        self.supportedOnOptitrack = supportedOnOptitrack
        self.supportedOnRealTime = supportedOnRealTime
        self.parameters = parameters
    }
}
