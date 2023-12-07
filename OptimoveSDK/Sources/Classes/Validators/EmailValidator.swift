//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

struct EmailValidator {
    enum Result: String {
        case valid
        case alreadySetIn
    }

    private let storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func isValid(_ email: String) -> EmailValidator.Result {
        guard email != storage.userEmail else {
            Logger.warn("Optimove: Email '\(email)' was already set in.")
            return .alreadySetIn
        }
        return .valid
    }
}
