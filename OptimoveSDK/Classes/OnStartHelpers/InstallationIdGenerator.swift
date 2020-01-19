//  Copyright © 2020 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class InstallationIdGenerator {

    private var storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func generate() {
        if storage.installationID == nil {
            storage.installationID = UUID().uuidString
        }
    }

}
