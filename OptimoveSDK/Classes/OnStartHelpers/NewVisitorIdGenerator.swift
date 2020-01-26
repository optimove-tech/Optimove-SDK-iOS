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
        let uuid = UUID().uuidString
        let sanitizedUUID = uuid.replacingOccurrences(of: "-", with: "")
        storage.initialVisitorId = VisitorIDPreprocessor.process(sanitizedUUID)
        if storage.visitorID == nil {
            storage.visitorID = storage.initialVisitorId
        }
    }
}
