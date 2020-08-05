//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore

struct UserIDValidator {

    enum Result: String {
        case valid
        case notValid
        case alreadySetIn
    }

    private let storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func validateNewUserID(_ userId: String) -> UserIDValidator.Result {
        guard UserIDValidator.isValid(userId) else {
            return .notValid
        }
        guard userId != storage.customerID else {
            return .alreadySetIn
        }
        return .valid
    }

    /// Validate that the user id that provided by the client, feets with optimove conditions for valid user id
    ///
    /// - Parameter userId: the client user id
    /// - Returns: An indication of the validation of the provided user id
    private static func isValid(_ userId: String) -> Bool {
        return !userId.isBlank &&
            (userId != "none") &&
            (userId != "undefined") &&
            (userId != "null") &&
            !userId.contains("undefine")
    }
}
