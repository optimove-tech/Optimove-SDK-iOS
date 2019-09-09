//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

extension OptimoveEvent {

    func matchConfiguration(with events: [String: EventsConfig]) throws -> (event: OptimoveEvent, config: EventsConfig) {
        guard let eventConfig = events[self.name] else {
            throw GuardError.custom("Configurations are missing for event \(self.name)")
        }
        return (self, eventConfig)
    }

}
