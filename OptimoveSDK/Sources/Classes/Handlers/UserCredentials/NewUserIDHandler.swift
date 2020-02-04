//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class NewUserIDHandler {

    private var storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func handle(userID: String) {
        storage.visitorID = VisitorIDPreprocessor.process(userID)
        storage.customerID = userID
    }

}
