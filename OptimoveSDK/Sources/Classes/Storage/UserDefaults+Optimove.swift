//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

public extension UserDefaults {
    enum Constants {
        static let suiteName: String = "com.optimove.sdk"
    }

    static func optimove() throws -> UserDefaults {
        let suiteName = Constants.suiteName
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw GuardError.custom("Unable to initialize UserDefault with suit name \(suiteName).")
        }
        return userDefaults
    }
}
