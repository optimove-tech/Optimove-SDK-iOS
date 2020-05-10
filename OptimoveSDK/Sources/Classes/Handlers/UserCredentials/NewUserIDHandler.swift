//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class NewUserIDHandler {

    private var storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func handle(userID: String) {
        storage.visitorID = userID.sha1().prefix(16).description.lowercased()
        storage.customerID = userID
    }

}
