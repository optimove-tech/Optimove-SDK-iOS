//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class NewUserHandler {

    private var storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func handle(user: User) {
        storage.customerID = user.userID
        storage.visitorID = user.visitorID
    }

}
