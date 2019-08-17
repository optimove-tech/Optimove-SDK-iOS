//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

import OptimoveCore

protocol EventsConfigWarehouse {
    func getConfig(for event: OptimoveEvent) -> EventsConfig?
}

struct OptimoveEventConfigsWarehouseImpl: EventsConfigWarehouse {

    private let events: [String: EventsConfig]

    init(events: [String: EventsConfig]) {
        self.events = events
    }

    func getConfig(for event: OptimoveEvent) -> EventsConfig? {
        return events[event.name]
    }
}
