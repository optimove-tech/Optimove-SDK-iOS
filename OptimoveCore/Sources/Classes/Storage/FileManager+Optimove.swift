//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public extension FileManager {

    static func optimoveURL() throws -> URL {
        return try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    /* Returns the container directory associated with the Optimove SDK group.
     */
    @available(swift, deprecated: 3.4.0, message: "Use `FileManager.optimove()` instead.")
    func groupContainer(tenantBundleIdentifier: String) throws -> URL {
        let groupIdentifier = "group.\(tenantBundleIdentifier).optimove"
        guard let url = self.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) else {
            throw GuardError.custom(
                """
                Unable to initialize FileManager container for the application group identifier "\(groupIdentifier)".
                Highly possible that the client forgot to add the app group as described in the documentation.
                Link: https://github.com/optimove-tech/Optimove-SDK-iOS/wiki/Optipush-Setup#3-setting-up-capabilities
                """
            )
        }
        return url
    }

}
