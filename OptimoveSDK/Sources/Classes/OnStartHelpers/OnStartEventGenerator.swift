//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class OnStartEventGenerator {

    private let coreEventFactory: CoreEventFactory
    private let synchronizer: Synchronizer
    private let storage: OptimoveStorage

    init(coreEventFactory: CoreEventFactory,
         synchronizer: Synchronizer,
         storage: OptimoveStorage) {
        self.coreEventFactory = coreEventFactory
        self.synchronizer = synchronizer
        self.storage = storage
    }

    func generate() {
        asyncGenerate()
        generateEvents()
    }

    private func generateEvents() {
        try? coreEventFactory.createEvent(.metaData) { event in
            self.synchronizer.handle(.report(event: event))
        }
        try? coreEventFactory.createEvent(.setAdvertisingId) { event in
            self.synchronizer.handle(.report(event: event))
        }
    }

    private func asyncGenerate() {
        UserAgentGenerator(
            storage: storage,
            synchronizer: synchronizer,
            coreEventFactory: coreEventFactory
        ).generate()
        AppOpenOnStartGenerator(
            synchronizer: synchronizer,
            coreEventFactory: coreEventFactory
        ).generate()
    }

}
