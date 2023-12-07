//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class NewEmailHandler {
    private var storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func handle(email: String) {
        storage.userEmail = email
    }
}
