//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public extension FileManager {

    /* Returns the container directory associated with the Optimove SDK group.
     */
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
