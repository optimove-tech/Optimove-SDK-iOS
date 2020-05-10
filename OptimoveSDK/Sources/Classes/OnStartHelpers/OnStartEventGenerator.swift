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
        tryCatch {
            let metaDataEvent = try coreEventFactory.createEvent(.metaData)
            let setAdvertisingIdEvent = try coreEventFactory.createEvent(.setAdvertisingId)
            self.synchronizer.handle(.report(events: [metaDataEvent, setAdvertisingIdEvent]))
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
