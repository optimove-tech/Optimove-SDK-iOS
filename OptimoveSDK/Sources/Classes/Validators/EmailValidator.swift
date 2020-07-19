//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

struct EmailValidator {

    enum Result: String {
        case valid
        case notValid
        case alreadySetIn
    }

    private let storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func isValid(_ email: String) -> EmailValidator.Result {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        guard emailTest.evaluate(with: email) else {
            Logger.error("Optimove: Email is not valid")
            return .notValid
        }
        guard email != storage.userEmail else {
            Logger.warn("Optimove: Email '\(email)' was already set in.")
            return .alreadySetIn
        }
        return .valid
    }
}
