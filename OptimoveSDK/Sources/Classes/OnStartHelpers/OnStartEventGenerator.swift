//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class OnStartEventGenerator {

    private let coreEventFactory: CoreEventFactory
    private let synchronizer: Pipeline
    private let storage: OptimoveStorage

    init(coreEventFactory: CoreEventFactory,
         synchronizer: Pipeline,
         storage: OptimoveStorage) {
        self.coreEventFactory = coreEventFactory
        self.synchronizer = synchronizer
        self.storage = storage
    }

    func generate() {
        asyncGenerate()
        syncGenerate()
    }

    private func syncGenerate() {
        tryCatch {
            let metaDataEvent = try coreEventFactory.createEvent(.metaData)
            self.synchronizer.deliver(.report(events: [metaDataEvent]))
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
