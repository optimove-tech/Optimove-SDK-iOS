//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

extension ProcessInfo {

    /// Return a string in format "A.B.C", where:
    /// A – major version,
    /// B – minor version,
    /// C – patch version
    /// of the device operation system.
    var operatingSystemVersionOnlyString: String {
        return [
            operatingSystemVersion.majorVersion,
            operatingSystemVersion.minorVersion,
            operatingSystemVersion.patchVersion
        ]
            .map { String($0) }
            .joined(separator: ".")
    }
}
