//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class OptimoveEventDecoratorFactory {
    static func getEventDecorator(forEvent event: OptimoveEvent) -> OptimoveEventDecorator {
        if event is OptimoveCoreEvent {
            return OptimoveEventDecorator(event: event)
        } else {
            return OptimoveCustomEventDecorator(event: event)
        }
    }

    static func getEventDecorator(forEvent event: OptimoveEvent, withConfig config: EventsConfig)
        -> OptimoveEventDecorator {
        let dec = getEventDecorator(forEvent: event)
        dec.processEventConfig(config)
        return dec
    }

    private init() {}
}
