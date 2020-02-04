//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

/// Use for validation a new APNs token.
struct APNsTokenValidator {

    enum Result {
        case new
        case old
    }

    private let storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    /// Validate an incoming APNs token with a stored one by comparing.
    /// - Parameter token: A validation result.
    func validate(token: Data) -> Result {
        guard let apnsToken = storage.apnsToken else {
            return .new
        }
        return token == apnsToken ? .old : .new
    }
}
