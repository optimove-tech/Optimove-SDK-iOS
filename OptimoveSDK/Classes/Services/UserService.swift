//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class UserService {

    private var storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func getUserID() throws -> String {
        do {
            return try storage.getCustomerID()
        } catch {
            Logger.debug(error.localizedDescription)
            return try storage.getInitialVisitorId()
        }
    }

}
