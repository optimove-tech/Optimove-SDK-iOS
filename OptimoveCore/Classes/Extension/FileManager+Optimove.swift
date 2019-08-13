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
                If this line is crashing the client forgot to add the app group as described in the documentation.
                Link: ttps://tinyurl.com/y3kfnjw9
                """
            )
        }
        return url
    }

}
