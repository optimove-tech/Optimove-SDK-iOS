//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public extension UserDefaults {

    /* Returns the UserDefaults associated with the Optimove SDK group.
     */
    static func grouped(tenantBundleIdentifier: String) throws -> UserDefaults {
        guard let userDefaults = UserDefaults(suiteName: "group.\(tenantBundleIdentifier).optimove") else {
            throw GuardError.custom(
            """
            If this line is crashing the client forgot to add the app group as described in the documentation.
            Link: https://github.com/optimove-tech/Optimove-SDK-iOS/wiki/Optipush-Setup#3-setting-up-capabilities
            """
            )
        }
        return userDefaults
    }

    /* Returns the UserDefaults associated with a host application.
     */
    static func shared(tenantBundleIdentifier: String) throws -> UserDefaults {
        guard let userDefaults = UserDefaults(suiteName: tenantBundleIdentifier) else {
            throw GuardError.custom(
                """
                The passed bundle identifier does not have any related UserDefault's container.
                """
            )
        }
        return userDefaults
    }

}
