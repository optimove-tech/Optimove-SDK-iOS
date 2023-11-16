//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class NewVisitorIdGenerator {
    private var storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func generate() {
        guard storage.initialVisitorId == nil else { return }
        storage.initialVisitorId = UUID().uuidString
        if storage.visitorID == nil {
            storage.visitorID = storage.initialVisitorId
        }
    }
}
