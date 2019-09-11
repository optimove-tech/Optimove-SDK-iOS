//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class OnStartEventGenerator {

    private let coreEventFactory: CoreEventFactory
    private let handler: HandlersPool
    private let storage: OptimoveStorage

    init(coreEventFactory: CoreEventFactory,
         handler: HandlersPool,
         storage: OptimoveStorage) {
        self.coreEventFactory = coreEventFactory
        self.handler = handler
        self.storage = storage
    }

    func generate() {
        tryCatch {
            let events = [
                try coreEventFactory.createEvent(.metaData),
                try coreEventFactory.createEvent(.setAdvertisingId),
            ].compactMap { $0 }
            try events.forEach { event in
                try handler.eventableHandler.handle(.init(.report(event: event)))
            }
        }
        UserAgentGenerator(
            storage: storage,
            handler: handler,
            coreEventFactory: coreEventFactory
        ).generate()
        AppOpenOnStartGenerator(
            handler: handler,
            coreEventFactory: coreEventFactory
        ).generate()
    }

}
