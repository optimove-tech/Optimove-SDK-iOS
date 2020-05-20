//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class FirstTimeVisitGenerator {

    private var storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func generate() {
        if storage.firstVisitTimestamp == nil {
            // Realtime server asked to get it in seconds
            storage.firstVisitTimestamp = Date().timeIntervalSince1970.seconds
        }
    }
}
