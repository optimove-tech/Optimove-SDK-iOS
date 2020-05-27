//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class FirstRunTimestampGenerator {

    private var storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func generate() {
        if storage.firstRunTimestamp == nil {
            // Realtime server asked to get it in seconds
            storage.firstRunTimestamp = Date().timeIntervalSince1970.seconds
        }
    }
}
