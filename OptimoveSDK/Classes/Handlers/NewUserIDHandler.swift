//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class NewUserIDHandler {

    private var storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func handle(userID: String) {
        if storage.customerID == nil {
            storage.isFirstConversion = true
        } else if userID != storage.customerID {
            Logger.info("user id changed from '\(storage.customerID ?? "nil")' to '\(userID)'")
            if let isRegistrationSuccess = storage.isRegistrationSuccess, isRegistrationSuccess == true {
                // send the first_conversion flag only if no previous registration has succeeded
                storage.isFirstConversion = false
            }
        }
        storage.visitorID = VisitorIDPreprocessor.process(userID)
        storage.customerID = userID
    }

}
