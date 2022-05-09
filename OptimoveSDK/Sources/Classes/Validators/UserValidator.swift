//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore

struct UserValidator {

    enum Result: String {
        case valid
        case alreadySetIn
    }

    private let storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func validateNewUser(_ user: User) -> UserValidator.Result {
        let userID = user.userID
        guard userID != storage.customerID else {
            return .alreadySetIn
        }
        return .valid
    }

}
