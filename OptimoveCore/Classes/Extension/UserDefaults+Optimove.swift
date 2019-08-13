//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public extension UserDefaults {

    static func grouped(tenantBundleIdentifier: String) throws -> UserDefaults {
        guard let userDefaults = UserDefaults(suiteName: "group.\(tenantBundleIdentifier).optimove") else {
            throw GuardError.custom(
            """
            If this line is crashing the client forgot to add the app group as described in the documentation.
            Link: ttps://tinyurl.com/y3kfnjw9
            """
            )
        }
        return userDefaults
    }

}
