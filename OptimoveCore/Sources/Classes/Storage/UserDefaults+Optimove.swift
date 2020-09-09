//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public extension UserDefaults {

    struct Constants {
        static let suiteName: String = "com.optimove.sdk"
    }

    static func optimove() throws -> UserDefaults {
        let suiteName = Constants.suiteName
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw GuardError.custom("Unable to initialize UserDefault with suit name \(suiteName).")
        }
        return userDefaults
    }

    /* Returns the UserDefaults associated with the Optimove SDK group.
     */
    @available(swift, deprecated: 3.4.0, message: "Use `UserDefaults.optimove()` instead.")
    static func grouped(tenantBundleIdentifier: String) throws -> UserDefaults {
        let suiteName = "group.\(tenantBundleIdentifier).optimove"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw GuardError.custom(
            """
            Unable to initialize UserDefault with suit name "\(suiteName)".
            Highly possible that the client forgot to add the app group as described in the documentation.
            Link: https://github.com/optimove-tech/Optimove-SDK-iOS/wiki/Optipush-Setup#3-setting-up-capabilities
            """
            )
        }
        return userDefaults
    }

    /* Returns the UserDefaults associated with a host application.
     */
    @available(swift, deprecated: 3.4.0, message: "Use `UserDefaults.optimove()` instead.")
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
