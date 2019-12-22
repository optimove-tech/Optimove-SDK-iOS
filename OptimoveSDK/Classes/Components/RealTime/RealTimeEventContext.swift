//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

// Using for defining type of realtime event.
enum RealTimeEventType {
    case regular
    case setUserID
    case setUserEmail
}

struct RealTimeEventContext {
    private(set) var event: OptimoveEvent
    private(set) var config: EventsConfig
    private(set) var type: RealTimeEventType

    init(event: OptimoveEvent,
         config: EventsConfig,
         type: RealTimeEventType) {
        self.event = event
        self.config = config
        self.type = type
    }

    func onSuccess(_ json: String) {
        Logger.debug("Realtime: Report success: \(event.name). Response: \(json)")
    }
}
