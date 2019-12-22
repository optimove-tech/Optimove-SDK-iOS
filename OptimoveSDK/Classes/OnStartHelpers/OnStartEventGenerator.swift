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
        [
            try? coreEventFactory.createEvent(.metaData),
            try? coreEventFactory.createEvent(.setAdvertisingId)
        ].compactMap { $0 }
        .forEach { synchronizer.handle(.report(event: $0)) }
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
