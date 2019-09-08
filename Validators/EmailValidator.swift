//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

struct EmailValidator {

    enum Result {
        case valid
        case notValid
    }

    static func isValid(_ email: String) -> EmailValidator.Result {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        guard emailTest.evaluate(with: email) else {
            Logger.error("Optimove: Email is not valid")
            return .notValid
        }
        return .valid
    }
}
